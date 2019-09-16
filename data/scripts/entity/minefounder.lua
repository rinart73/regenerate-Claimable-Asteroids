
local rca_foundFactory = MineFounder.foundFactory
function MineFounder.foundFactory(goodName, productionIndex, name)
    if anynils(goodName, productionIndex, name) then return end

    rca_foundFactory(goodName, productionIndex, name)
    --RegenerativeClaimableAsteroids - Dirtyredz|David McClain
    RCA = include("data/scripts/lib/RegenerativeClaimableAsteroidsLib")
    RCA.DecreaseSectorCount(Sector())
    RCA.IncreaseServerRespawnCount()
    --RegenerativeClaimableAsteroids - Dirtyredz|David McClain
end
