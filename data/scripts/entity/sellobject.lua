function sell(receiverIndex)
    if anynils(receiverIndex) then return end

    local owner, self = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageStations)
    if not owner then return end

    local factions = getFactions()
    local faction = factions[receiverIndex]

    owner:receive("Sold an object for %1% credits."%_T, faction.price)
    changeRelations(Faction(faction.index), owner, faction.reputation, RelationChangeType.Commerce)

    self.factionIndex = faction.index

    --RegenerativeClaimableAsteroids - Dirtyredz|David McClain
    RCA = include("data/scripts/lib/RegenerativeClaimableAsteroidsLib")
    RCA.tag(self, "sold")
    RCA.AddToPreviousSellersList(self, owner.index)
    --RegenerativeClaimableAsteroids - Dirtyredz|David McClain

    terminate()
end
