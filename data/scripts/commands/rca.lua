if onServer() then
  function execute(sender, commandName, one, ...)
      local args = {...}
      local Server = Server()
      local Player = Player(sender)
      local script = Player:hasScript("mods/RegenerativeClaimableAsteroids/scripts/player/RegenerativeClaimableAsteroids.lua")
      if script == true then
        Player:removeScript("mods/RegenerativeClaimableAsteroids/scripts/player/RegenerativeClaimableAsteroids.lua")
      end
      Player:addScriptOnce("mods/RegenerativeClaimableAsteroids/scripts/player/RegenerativeClaimableAsteroids.lua")
      Player:sendChatMessage('RegenerativeClaimableAsteroids', 0, "RegenerativeClaimableAsteroids Added")

      return 0, "", ""
  end

  function getDescription()
      return ""
  end

  function getHelp()
      return ""
  end
end
