package.path = package.path .. ";data/scripts/?.lua"
local SectorSpecifics = include("sectorspecifics")

local RCA = {}
--RCA.CLAIMASTRO = "RCA_Claimable"
RCA.PREVIOUS = "RCA_Previous_"
RCA.TOTAL = "RCA_Total"
RCA.TIMESTAMP = "RCA_TimeStamp"
RCA.RESPAWNCOUNT = "RCA_RespawnCount"
RCA.TAG = "RCA_Tag"
RCA.RESPAWNTIMESTAMP = "RCA_RespawnTimeStamp"
RCA.LASTVISITED = "RCA_LastVisited"

function RCA.GetpreviousSellersList(Entity)
    local previousSellers = {}
    for i = 1, 5 do
        table.insert(previousSellers, Entity:getValue(RCA.PREVIOUS .. i))
    end
    return previousSellers
end

function RCA.AddToPreviousSellersList(Entity, playerIndex)
    local previousSellers = RCA.GetpreviousSellersList(Entity)
    table.insert(previousSellers, 1, playerIndex)
    for i = 1, 5 do
        Entity:setValue(RCA.PREVIOUS .. i, previousSellers[i])
    end
end

function RCA.HasPreviouslySold(Entity, playerIndex)
    local previousSellers = RCA.GetpreviousSellersList(Entity)
    for i = 1, 5 do
        if previousSellers[i] == playerIndex then
            return true
        end
    end
    return false
end

function RCA.tag(Entity, RCA_Type)
    Entity:setValue(RCA.TAG, RCA_Type)
    local currentTime = Server().runtime
    Entity:setValue(RCA.TIMESTAMP, currentTime)
end

function RCA.DecreaseSectorCount(Sector)
    Sector:setValue(RCA.TOTAL, math.max(0, (Sector:getValue(RCA.TOTAL) or 0) - 1))
end

function RCA.IncreaseServerRespawnCount()
    Server():setValue(RCA.RESPAWNCOUNT, (Server():getValue(RCA.RESPAWNCOUNT) or 0) + 1)
end

function RCA.isSectorEmpty(x,y)
  local regular, offgrid,_ =  SectorSpecifics():determineContent(x, y, Server().seed)
  return (not regular and not offgrid)
end

return RCA
