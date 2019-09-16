-- Allow other scripts to hook in.
-- Has all local variables as arguments ('callingPlayer' is an implicit "global").

local RCA = include("data/scripts/lib/RegenerativeClaimableAsteroidsLib")
local rca_claim = claim
function claim()
    local entity = Entity()
    local faction, ship, player = getInteractingFaction(callingPlayer)
    if RCA.HasPreviouslySold(entity, faction.index) then
        Player(callingPlayer):sendChatMessage("Server", 1, "You've previously claimed this asteroid!")
        return
    end
    RCA.tag(entity, "claimed")
    rca_claim()
end
