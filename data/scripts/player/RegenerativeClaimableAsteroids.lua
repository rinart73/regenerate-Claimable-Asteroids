package.path = package.path .. ";data/scripts/lib/?.lua"
include("utility")

-- namespace RegenerativeClaimableAsteroids
RegenerativeClaimableAsteroids = {}

if onServer() then

--[[local Azimuth = include("azimuthlib-basic")
local configOptions = {
  _version = {default = "0.1", comment = "Config version. Don't touch."},
  LogLevel = {default = 2, min = 0, max = 4, format = "floor", comment = "0 - Disable, 1 - Errors, 2 - Warnings, 3 - Info, 4 - Debug."}
}
local azConfig, isModified = Azimuth.loadConfig("RCA", configOptions, nil, true)
if isModified then
    Azimuth.saveConfig("RCA", azConfig, configOptions, nil, true)
end
local log = Azimuth.logs("RCA", azConfig.LogLevel)
]]
local RCA = include('data/scripts/lib/RegenerativeClaimableAsteroidsLib')
--Config Settings
local config = include('data/config/RegenerativeClaimableAsteroidsConfig')
local DELAYS = {respawn= config.RespawnDelay,claimed=config.UnClaimDelay, sold=config.UnSellDelay, serverRespawn= config.ServerRespawnDelay}

function RegenerativeClaimableAsteroids.initialize()
    --log.Info('RegenerativeClaimableAsteroids initialize')
    local sector = Sector()
    local player = Player()
    local playerIndex = player.index
    local x, y = sector:getCoordinates()

    player:registerCallback("onSectorEntered", "onSectorEntered")
    RegenerativeClaimableAsteroids.onSectorEntered(playerIndex, x, y)
end

function RegenerativeClaimableAsteroids.onSectorEntered(playerIndex, x, y)
    if RCA.isSectorEmpty(x,y) then --[[log.Info("This sector is Empty", x , y)]] return end

    if Player().index ~= playerIndex then return end
    local sector = Sector()
    --log.Debug("onSectorEntered in Sector: ("..x..", "..y..")")

    --Get All asteroids in sector
    local unclaimedAsteroids = {sector:getEntitiesByScript("claim.lua")}
    local tamperedAsteroids = {sector:getEntitiesByScriptValue(RCA.TAG) }
    local ClaimableAsteroidsCount = 0

    for i=1, #unclaimedAsteroids do
        ClaimableAsteroidsCount = ClaimableAsteroidsCount + 1
    end

    for _,asteroid in pairs(tamperedAsteroids) do
        local factionIndex = asteroid.factionIndex
        if factionIndex == 0 then -- untampreded, shouldn't be in the tampered list
            --log.Warn("Asteroid is not owned by anyone")
        elseif Faction(factionIndex).isPlayer or Faction(factionIndex).isAlliance then  -- claimed by an player / alliance
            --log.Debug("Asteroid is owned by a player or alliance")
            RegenerativeClaimableAsteroids.tryReset(asteroid, "claimed", playerIndex)
        else -- sold
            --log.Debug("Asteroid is owned by an AI-faction")
            RegenerativeClaimableAsteroids.tryReset(asteroid, "sold")
        end
        ClaimableAsteroidsCount = ClaimableAsteroidsCount + 1
    end --End Iteration

    --If theres too many asteroids in the sector (fix for marking breeders, and safety for exploiters)
    if ClaimableAsteroidsCount <= config.MaxPerSector then
        --log.Info("Found a total of: " .. ClaimableAsteroidsCount .. " Claimable Asteroid(s)", x, y)
        RegenerativeClaimableAsteroids.CheckSectorRespawn(ClaimableAsteroidsCount, x, y)
        RegenerativeClaimableAsteroids.CheckServerRespawn(x, y)
    else
        --log.Info("Too many asteroids, Found: " .. ClaimableAsteroidsCount .. " Removing RCA sectors values", x, y)
    end

    sector:setValue(RCA.LASTVISITED, Server().runtime)
end

function RegenerativeClaimableAsteroids.tryReset(asteroid, tag, playerIndex)

    local serverRuntime = Server().runtime
    local RCA_TAG = asteroid:getValue(RCA.TAG)
    local RCA_TimeStamp = asteroid:getValue(RCA.TIMESTAMP)
    if not RCA_TAG or not RCA_TimeStamp or RCA_TAG ~= tag then
        --log.Warn("Asteroid tampered, but not properly tagged. Tagging it.", RCA_TAG, tag, RCA_TimeStamp)
        asteroid:setValue(RCA.TAG, tag)
        asteroid:setValue(RCA.TIMESTAMP, serverRuntime)
        return
    end
    --log.Debug("Asteroid has Tag & Stamp.", RCA_TAG, tag, RCA_TimeStamp)
    if tag == "claimed" and playerIndex then -- increase owning time, when a player revisits its claimed asteroid(s)
        local allianceIndex = Player(playerIndex).allianceIndex
        if asteroid.factionIndex == playerIndex or asteroid.factionIndex == allianceIndex then
            --log.Info("Asteroid is owned by player or players alliance who already claimed this asteroid, only updating timestamp!")
            asteroid:setValue(RCA.TIMESTAMP, serverRuntime)
            return
        end
    end

    --Check if timestamp is older by delay time
    if RegenerativeClaimableAsteroids.compareTime(RCA_TimeStamp, DELAYS[tag]) then
        --Timestamp threshold exceeded, RESET
        --log.Info("RCA_TimeStamp threshold exceeded, Resetting now!")
        RegenerativeClaimableAsteroids.ResetAsteroid(asteroid)
    else
        --log.Debug("RCA_TimeStamp is within config option ", tag)
    end
end

function RegenerativeClaimableAsteroids.CheckSectorRespawn(AsteroidCount, x, y)
    local sector = Sector()

    --Check for RCA_LastVisited and set if missing
    local RCA_LastVisited = sector:getValue(RCA.LASTVISITED)
    if not RCA_LastVisited then
        RegenerativeClaimableAsteroids.SetSectorTimestamp()
    end

    --Check if sector needs to respawn any missing asteroids
    local maxNumAstro = sector:getValue(RCA.TOTAL) or 0
    --log.Debug("Sector is marked for a total of: " .. maxNumAstro .. " asteroid(s)")

    if maxNumAstro < AsteroidCount then
        --log.Info("Sector more than the marked number, Reset", maxNumAstro, AsteroidCount)
        --Assign AsteroidCount to the sector
        sector:setValue(RCA.TOTAL, AsteroidCount)
        return
    end

    if maxNumAstro == AsteroidCount and maxNumAstro > 0 then
        --log.Debug("Sector has no missing asteroids", maxNumAstro, AsteroidCount)
        return
    end

    --how many asteroids are we missing?
    local MissingAsteroids = maxNumAstro - AsteroidCount

    if MissingAsteroids <= 0 then
        --log.Debug("Sector has 0 claimable asteroids", maxNumAstro, AsteroidCount)
        return
    end

    --log.debug("Seems we're missing " .. MissingAsteroids .. " asteroid(s)")

    if RegenerativeClaimableAsteroids.compareTime(RCA_LastVisited, config.RespawnDelay) then
        --log.Info("Its been more than " .. config.RespawnDelay .. " seconds since anyones visted the sector, Respawning " .. MissingAsteroids .. " asteroids.")

        --Double check were not over the maximum
        if MissingAsteroids > config.MaxPerSector then
            --log.Warn('Somehow we had more then the maxium, only counting to maximum', MissingAsteroids, config.MaxPerSector)
            MissingAsteroids = config.MaxPerSector
        end

        --Create an asteroid for each missing asteroid
        for i=1, MissingAsteroids, 1 do
            RegenerativeClaimableAsteroids.RespawnAsteroid(x, y)
        end
    else
        --log.Debug("Not enought time has passed, Not spawning any asteroids.")
    end
end

function RegenerativeClaimableAsteroids.CheckServerRespawn(x, y)
    local server = Server()

    --Check if server pool has an asteroids to spawn
    local RCA_RespawnCount = server:getValue(RCA.RESPAWNCOUNT) or 0
    if RCA_RespawnCount == 0 then
          --No asteroids to spawn
          --log.Info("No asteroids to respawn")
        return
    end

    --log.Info("Server has: " .. RCA_RespawnCount .. " Asteroids it needs to spawn.")

    --Determine, if this sector entering will respawn an Asteroid from the server-pool
    if math.random() < (config.RespawnChance / 100) then
        --Get Server Timestamp for last mine created or last roid spawned for the server
        local serverRuntime = server.runtime
        local RCA_RespawnTimeStamp = server:getValue(RCA.RESPAWNTIMESTAMP)
        if not RCA_RespawnTimeStamp then
            server:setValue(RCA.RESPAWNTIMESTAMP, serverRuntime)
            return
        end

        local ForceTime = false
        if RCA_RespawnCount > 50 then
            --log.Info("There are more than 50 asteroids in the pool, ignoring the time requirment.")
            ForceTime = true
        end

        --Players one the draw, has there been enough time passed to spawn one?
        if RegenerativeClaimableAsteroids.compareTime(RCA_RespawnTimeStamp, config.ServerRespawnDelay) or ForceTime then

            --WINNER spawn asteroid, reset server timestamp, and reduce server pool count.
            --log.Info("Asteroid spawning, from server pool.")
            RegenerativeClaimableAsteroids.RespawnAsteroid(x, y)
            server:setValue(RCA.RESPAWNCOUNT, RCA_RespawnCount-1)
            server:setValue(RCA.RESPAWNTIMESTAMP, serverRuntime)
        end
    end
end

function RegenerativeClaimableAsteroids.SetSectorTimestamp()
    Sector():setValue(RCA.LASTVISITED, Server().runtime)
end

function RegenerativeClaimableAsteroids.compareTime(EntityTimeStamp, delay)
    local serverRuntime = Server().runtime
    local comparetime = serverRuntime - EntityTimeStamp

    --log.Debug("Server Runtime: " .. serverRuntime .. ", EntityTimeStamp: " .. EntityTimeStamp .. ", Comparetime: " .. comparetime .. ", TimeDelay: " .. delay)
    return comparetime > delay
    -- return (Server().runtime - EntityTimeStamp) > delay
end

function RegenerativeClaimableAsteroids.RespawnAsteroid(x, y)
    local SectorGenerator = include ("SectorGenerator")
    SectorGenerator(x, y):createClaimableAsteroid()
    --log.Debug("Claimable Asteroid Spawned!", x, y)
end

function RegenerativeClaimableAsteroids.ResetAsteroid(asteroid)
    --Reset owner
    asteroid.factionIndex = 0

    --Reset all scripts
    for _, script in pairs(asteroid:getScripts()) do
        asteroid:removeScript(script)
    end
    asteroid:addScriptOnce("claim.lua")

    --Remove asteroids RCA values
    asteroid:setValue(RCA.TAG, nil)
    asteroid:setValue(RCA.TIMESTAMP, nil)

    --log.Info("Claimable Asteroid Reset!")
end


end
