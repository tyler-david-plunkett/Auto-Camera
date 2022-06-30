defaultSettings = {
  general = {
    standByOnLoad = false,
    standByBehavior = "view",
    manualStandByView = 5,
    petBattleView = 5,
    instanceEncounterView = 5,
    ridingDistance = 8.5,
    speedMultiplier = 0.2,
    normalEnemyDistance = 4,
    eliteEnemyDistance = 4,
    raidEnemyDistance = 8,
    bossEnemyDistance = 50,
  },
  actionCam = {
    suppressExperimentalCVarPrompt = false
    -- actionCam CVars are added here on VARIABLES_LOADED event
  }
}

settingsUpdateMap = {}

settingsUpdateMap['0.2.0'] = function(settings)
  -- copy root as general
  local general = deepCopy(settings)

  -- empty table
  for key in pairs(settings) do
    settings[key] = nil
  end

  settings.general = general
  settings.version = '0.2.0'
end
