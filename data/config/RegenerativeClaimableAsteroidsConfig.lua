local Config = {}

Config.ModPrefix = "[Regenerative Claimable Asteroids]";
Config.Version = "[1.0.0]";
-- 60 *60 *24 *5  --5 Days
Config.RespawnDelay =24 *1 --0 = immediate, Seconds for the sector to respawn a moved or destroyed asteroid
Config.UnClaimDelay = 24 *1 --0 = immediate, Seconds until an asteroid will unclaim itself when a player has not sold/built the asteroid
Config.UnSellDelay = 16 --0 = immediate, Seconds until an asteroid will revert to no owner after being sold to a faction
Config.ServerRespawnDelay = 4 --0 immediate, Time delay between randomly spawning an asteroid to a random player on the server

Config.RespawnChance = 99 --0 = no chance, Percent chance that a random player will spawn an asteroid that was previously turned into a mine
Config.MaxPerSector =  3 --Number of max claimable asteroids per sector
Config.InactiveSectorRespawn = false --true = sector must be inactive for RespawnDelay seconds before respawning

return Config
