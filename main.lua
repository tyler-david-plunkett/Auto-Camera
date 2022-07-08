local addonName, vars = ...
AutoCamera = LibStub("AceAddon-3.0"):NewAddon(addonName)
local addon = AutoCamera
local STAND_BY = false
local IN_PET_BATTLE = false
local IN_ENCOUNTER = false
local IN_BARBER_SHOP = false
local IN_RAID = false
local IN_DUNGEON = false
local previousCameraZoom = GetCameraZoom()
local deltaTime = 0.1
local previousSettings = {general = nil, actionCam = nil} -- stores the previous settings when defaults are applied by the user
local playerRace = UnitRace("player")
local showOtherRaces = false
local races = set {"Human", "Dwarf", "Night Elf", "Gnome", "Draenei", "Worgen", "Pandaren", "Orc", "Undead", "Tauren", "Troll", "Blood Elf", "Goblin", "Void Elf", "Lightforged Draenei", "Dark Iron Dwarf", "Kul Tiran", "Mechagnome", "Nightborne", "Highmountain Tauren", "Mag'har Orc", "Zandalari Troll", "Vulpera"}
races[playerRace] = true -- adds player race if it's missing from race set
local maxZoomDistance = 50
local xpac = tonumber(string.match(GetBuildInfo(), "([0-9]+)\..*"))
local xpacs = {
    classic = 1,
    bcc = 2,
    wolc = 3,
    cata = 4,
    mop = 5,
    wod = 6,
    leg = 7,
    boa = 8,
    sl = 9
}
local actionCamCVars = {} -- populated on VARIABLES_LOADED event
local motionSicknessSettingValues = {}
motionSicknessSettingValues[1] = "Keep Character Centered"
motionSicknessSettingValues[2] = "Reduce Camera Motion"
motionSicknessSettingValues[3] = "Keep Character Centered and Reduce Camera Motion"
motionSicknessSettingValues[0] = "Allow Dynamic Camera Movement"

-- todo> move loops?
for key, command in pairs(C_Console.GetAllCommands()) do
    if (command.commandType == 0 and strfind(command.command, 'test_camera') ~= nil) then
        table.insert(actionCamCVars, command.command)
    end
end

for index, CVar in pairs(actionCamCVars) do
    defaultSettings.actionCam[CVar] = C_CVar.GetCVarDefault(CVar)
end

actionCamCommandOptions = {
    general = {
        "full", "basic", "off", "on", "default"
    },
    headMovement = {
        "heavyHeadMove", "noHeadMove", "lowHeadMove", "headMove"
    },
    targetFocus = {
        "focusAll", "focusEnemy", "focusInteract", "focusOff"
    }
}

function standingArgKey(race)
    return camelCase(race) .. 'Distance'
end

function enemyArgKey(unit)
    local enemyType
	if (
		(unitClassification == "worldboss" or
		(unitClassification == "elite" and UnitLevel(unit) == -1))
	) then
        enemyType = "boss"
    elseif (IN_RAID or IN_DUNGEON) then
        enemyType = "raid"
	elseif (
		unitClassification == "elite"
	) then
		enemyType = "elite"
	else
		enemyType = "normal"
    end
    
    return enemyType .. "EnemyDistance"
end

local playerStandingArgKey = standingArgKey(playerRace)

for race in pairs(set {"Worgen"}) do
    defaultSettings.general[standingArgKey(race)] =  4.6
end

for race in pairs(set {"Night Elf", "Nightborne"}) do
    defaultSettings.general[standingArgKey(race)] =  4
end

for race in pairs(set {"Draenei", "Pandaren" ,"Orc", "Troll", "Mag'har Orc", "Zandalari Troll", "Lightforged Draenei"}) do
    defaultSettings.general[standingArgKey(race)] =  4.5
end

for race in pairs(set {"Human", "Dwarf", "Undead", "Blood Elf" ,"Void Elf", "Dark Iron Dwarf"}) do
    defaultSettings.general[standingArgKey(race)] = 3.5
end

for race in pairs(set {"Gnome", "Goblin", "Mechagnome", "Vulpera"}) do
    defaultSettings.general[standingArgKey(race)] = 2
end

for race in pairs(set {"Tauren", "Kul Tiran", "Highmountain Tauren"}) do
    defaultSettings.general[standingArgKey(race)] = 5.2
end

local settings = defaultSettings
local units = {}
units[1] = 'target'
for i = 1, 10 do
    units[i + 1] = 'nameplate' .. i
end

BINDING_HEADER_AUTO_CAMERA = "Auto-Camera"
BINDING_NAME_TOGGLE_STAND_BY = "Toggle Stand-By Mode"

function addon:isRunning() 
    return 
        not STAND_BY and
        not IN_ENCOUNTER and
        not IN_PET_BATTLE and
        not IN_BARBER_SHOP
end

function addon:loadSettings()
    settings = addon.db.global

    -- assume earliest version
    settings.version = settings.version or "0.0.0"

    -- todo: test settings update
    -- update settings if necessary
    if (settings.version ~= version) then
        addon:updateSettings(settings)
    end

    deepMerge(settings, deepMerge(deepCopy(defaultSettings), settings, true))
end

function addon:updateSettings(settings)
    for updateVersion, updateFunction in pairs(settingsUpdateMap) do
        if (updateVersion > settings.version) then
            updateFunction(settings)
        end
    end

    settings.version = version
    return settings
end

-- addon hook callback functions
function addon:OnInitialize()
    local options = addon:options()
    addon.db = LibStub("AceDB-3.0"):New("AutoCameraDB", {global = defaultSettings}, true)
    addon:loadSettings()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)

    STAND_BY = settings.general.standByOnLoad

    -- disable experimental feature prompt if configured
    if (settings.actionCam.suppressExperimentalCVarPrompt) then
        UIParent:UnregisterEvent("EXPERIMENTAL_CVAR_CONFIRMATION_NEEDED") -- todo> reenable?
    end

    if (not STAND_BY) then
        addon:autoZoom()
    end
end

-- helper functions
function addon:toggleStandBy()
    if (STAND_BY) then
        STAND_BY = false
        addon:autoZoom()
    else
        STAND_BY = true
    end
    LibStub("AceConfigRegistry-3.0"):NotifyChange("Auto-Camera")
end

function addon:enterStandBy()
    STAND_BY = true
end

function addon:exitStandBy()
    STAND_BY = false
    if addon:isRunning() then
        addon:autoZoom()
    end
end

function addon:autoZoom()
    local targetZoom
    local currentCameraZoom = GetCameraZoom()
    local unit
    local enemyCount = 0
    local currentSpeed, runSpeed, flightSpeed, swimSpeed = GetUnitSpeed("player")

    targetZoom = settings.general[playerStandingArgKey]
    if (playerRace == "Worgen" and not isWorgenForm()) then
        targetZoom = settings.general.humanDistance
    end
    
    if (
        AuraUtil.FindAuraByName("Running Wild", "player") == nil and
        (IsMounted("player") or (UnitInVehicle and UnitInVehicle("player")))
    ) then
        targetZoom = settings.general.ridingDistance
    end

    targetZoom = targetZoom + currentSpeed * settings.general.speedMultiplier

    local enemyPackDistance = targetZoom
    for i, unit in ipairs(units) do
        local unitClassification = UnitClassification(unit)
        local unitLevel = UnitLevel(unit)
        if (
            not UnitIsDead(unit) and
            UnitCanAttack("player", unit) and
            CheckInteractDistance(unit, 1) and
            (unit == 'target' or UnitGUID('target') ~= UnitGUID(unit)) -- if unit is target or a unit with nameplate that isn't the target (avoids counting target twice)
        ) then
            enemyPackDistance = enemyPackDistance + settings.general[enemyArgKey(unit)]
        end
    end

    if (targetZoom < enemyPackDistance) then targetZoom = enemyPackDistance end

    local distanceDiff = targetZoom - currentCameraZoom
    
    -- todo fix over-zoom bug
    if (abs(distanceDiff) > 0.1) then
        local cameraZoomSpeed = distanceDiff / tonumber(GetCVar("cameraZoomSpeed"))
        if (cameraZoomSpeed < 0) then cameraZoomSpeed = cameraZoomSpeed * -1 end
        if (distanceDiff > 0) then
            MoveViewInStart(0)
            MoveViewOutStart(cameraZoomSpeed)
        else
            MoveViewOutStart(0)
            MoveViewInStart(cameraZoomSpeed)
        end
    else
        MoveViewInStop()
        MoveViewOutStop()
    end

    if (addon:isRunning()) then
        C_Timer.After(deltaTime, function() addon:autoZoom() end)
    else
        MoveViewInStop()
        MoveViewOutStop()
        if STAND_BY then
            if (settings.general.standByBehavior == "view") then
                SetView(settings.general.manualStandByView)
            elseif (settings.general.standByBehavior == "maxDistance") then
                CameraZoomOut(maxZoomDistance)
            end
        elseif IN_ENCOUNTER then
            if (settings.general.standByBehavior == "view") then
                SetView(settings.general.instanceEncounterView)
            elseif (settings.general.standByBehavior == "maxDistance") then
                CameraZoomOut(maxZoomDistance)
            end
        elseif IN_PET_BATTLE then
            if (settings.general.standByBehavior == "view") then
                SetView(settings.general.petBattleView)
            elseif (settings.general.standByBehavior == "maxDistance") then
                CameraZoomOut(maxZoomDistance)
            end
        end
    end

    previousCameraZoom = currentCameraZoom
end

function addon:applyActionCamSettings() 
    for index, CVar in pairs(actionCamCVars) do
        C_CVar.SetCVar(CVar, settings.actionCam[CVar])
    end
end

function addon:storeActionCamSettings() 
    for index, CVar in pairs(actionCamCVars) do
        settings.actionCam[CVar] = C_CVar.GetCVar(CVar, settings.actionCam[CVar])
    end
end

function viewOption()
    return {
        type = 'range',
        min = 1,
        max = 5,
        step = 1
    }
end

function distanceOption()
    return {
        type = 'range',
        min = 0,
        max = maxZoomDistance,
        step = 0.1,
        order = 3
    }
end

function addon:toggleGeneralDefaults()
    if (previousSettings.general == nil) then
        previousSettings.general = deepCopy(settings.general)
        deepMerge(settings.general, defaultSettings.general)
    else
        deepMerge(settings.general, previousSettings.general)
        previousSettings.general = nil
    end
end

function addon:toggleActionCamDefaults()
    if (previousSettings.actionCam == nil) then
        previousSettings.actionCam = deepCopy(settings.actionCam)
        deepMerge(settings.actionCam, defaultSettings.actionCam)
    else
        deepMerge(settings.actionCam, previousSettings.actionCam)
        previousSettings.actionCam = nil
    end
    addon.applyActionCamSettings()
end

function addon:cameraCharacterCenteringEnabled()
    return C_CVar.GetCVar("CameraKeepCharacterCentered") == "1"
end

function addon:cameraCharacterCenteringDisabled()
    return not addon.cameraCharacterCenteringEnabled()
end

-- options
function addon:options()
    local options = {
        type = 'group',
        name = 'Auto-Camera',
        childGroups = "tab",
        args = {
            general = {
                type = 'group',
                name = 'General',
                order = 1,
                set = function(info, value)
                    previousSettings.general = nil
                    settings.general[info[#info]] = value
                end,
                get = function(info) return settings.general[info[#info]] end,
                args = {
                    standBy = {
                        type = "group",
                        inline = true,
                        order = 1,
                        name = "Stand-By Mode",
                        args = {
                            toggleStandBy = {
                                type = "execute",
                                name = function()
                                    if (STAND_BY) then
                                        return "Exit Stand-By"
                                    else
                                        return "Enter Stand-By"
                                    end
                                end,
                                func = function() addon:toggleStandBy() end,
                                order = 1
                            },
                            standByOnLoad = {
                                type = "toggle",
                                name = "Load In Stand-By",
                                desc = "Controls if automatic camera zooming should be on stand-by on load",
                                order = 2
                            },
                            standByKeybinding = {
                                type = "keybinding",
                                name = "Toggle Key Binding",
                                desc = "Keybinding to toggle Stand-By Mode",
                                get = function()
                                    return GetBindingKey("TOGGLE_STAND_BY")
                                end,
                                set = function(info, value)
                                    local toggleStandByKey = GetBindingKey("TOGGLE_STAND_BY")
                                    if (toggleStandByKey) then
                                        SetBinding(toggleStandByKey) -- unbind current key
                                    end
                                    SetBinding(value, "TOGGLE_STAND_BY") -- bind toggle to entered key
                                    SaveBindings(2)
                                end,
                                order = 3
                            },
                            standByBehavior = {
                                type = "select",
                                name = "When Stand-By is activated",
                                order = 4,
                                values = {
                                    view = "Zoom to view",
                                    doNothing = "Do Nothing"
                                },
                                desc = "Indicates if the camera should zoom to the max camera distance when Auto-Camera is on stand-by"
                            },
                            spacer = {
                                type = "header",
                                name = "Stand-By Views",
                                order = 5,
                                hidden = function() return settings.general.standByBehavior ~= "view" end
                            },
                            manualStandByView = merge(viewOption(), {
                                name = 'Manual Stand-By View',
                                desc = 'The camera view to go to when toggling Auto-Camera off',
                                order = 6,
                                hidden = function() return settings.general.standByBehavior ~= "view" end
                            }),
                            instanceEncounterView = merge(viewOption(), {
                                name = 'Instance Encounter View',
                                desc = 'The camera view to go to during an encounter (e.g. boss battle)',
                                order = 7,
                                hidden = function() return settings.general.standByBehavior ~= "view" end
                            }),
                            petBattleView = merge(viewOption(), {
                                name = 'Pet Battle View',
                                desc = 'The camera view to go to during a pet battle.',
                                order = 8,
                                hidden = function() return settings.general.standByBehavior ~= "view" end
                            })
                        }
                    },
                    standingDistances = {
                        type = "group",
                        inline = true,
                        order = 2,
                        name = "Minimum Camera Distances by Race",
                        args = {
                            toggleHidden = {
                                type = "execute",
                                name = function()
                                    if showOtherRaces then
                                        return "Show Fewer Races"
                                    else
                                        return "Show More Races"
                                    end
                                end,
                                func = function() showOtherRaces = not showOtherRaces end,
                                order = 99
                            }
                        }
                    },
                    contextualDistances = {
                        type = "group",
                        inline = true,
                        order = 3,
                        name = "Contextual Camera Distances",
                        args = {
                            ridingDistance = merge(distanceOption(), {
                                name = 'Riding',
                                desc = 'Camera distance when riding on a mount or in a vehicle',
                                order = 1
                            }),
                            speedMultiplier = {
                                type = 'range',
                                name = 'Movement Multiplier',
                                min = 0,
                                max = 0.5,
                                step = 0.1,
                                order = 2
                            },
                            normalEnemyDistance = merge(distanceOption(), {
                                name = 'Per Normal Enemy',
                                desc = 'Distance to add per normal enemy on screen near the player character',
                                order = 3
                            }),
                            eliteEnemyDistance = merge(distanceOption(), {
                                name = 'Per Elite Enemy',
                                desc = 'Distance to add per elite enemy on screen near the player character',
                                order = 4
                            }),
                            raidEnemyDistance = merge(distanceOption(), {
                                name = 'Per Raid Enemy',
                                desc = 'Distance to add per raid enemy on screen near the player character',
                                order = 5,
                            }),
                            bossEnemyDistance = merge(distanceOption(), {
                                name = 'Per Boss Enemy',
                                desc = 'Distance to add per boss enemy on screen near the player character',
                                order = 6
                            })
                        }
                    },
                    toggleDefaults = {
                        type = "execute",
                        name = function()
                            if (previousSettings.general == nil) then
                                return "Defaults"
                            else
                                return "Undo"
                            end
                        end,
                        func = function() addon:toggleGeneralDefaults() end,
                        order = 100
                    }
                }
            },
            actionCam = {
                type = 'group',
                name = 'Action Cam',
                desc = 'This is an experimental feature of the base game that pairs well with Auto-Camera. This tab simply provides a convenient interface for configuration.',
                order = 2,
                set = function(info, value)
                    previousSettings.actionCam = nil
                    settings.actionCam[info[#info]] = value
                end,
                get = function(info) return settings.actionCam[info[#info]] end,
                args = {
                    general = {
                        type = "group",
                        inline = true,
                        order = 1,
                        name = "General",
                        args = {
                            motionSickness = {
                                name = "Motion Sickness",
                                type = "select",
                                order = 1,
                                values = motionSicknessSettingValues,
                                width = "full",
                                desc = "Must be set to Allow Dynamic Camera Movement or Reduce Camera Motion to enable Action Cam. This accessibility setting and more can be found in Game Menu > Interface > Accessibility.",
                                set = function(info, value)
                                    SetCVar("CameraKeepCharacterCentered", (value == 1 or value == 3) and "1" or "0")
                                    SetCVar("CameraReduceUnexpectedMovement", (value == 2 or value == 3) and "1" or "0")

                                    if (addon.cameraCharacterCenteringEnabled()) then
                                        ConsoleExec("ActionCam off")
                                    else
                                        addon.applyActionCamSettings()
                                    end
                                end,
                                get = function()
                                    return ((GetCVar("CameraKeepCharacterCentered") == "1" and 1 or 0) + (GetCVar("CameraReduceUnexpectedMovement") == "1" and 2 or 0))
                                end
                            },
                            suppressExperimentalCVarPrompt = {
                                type = "toggle",
                                order = 2,
                                width = "full",
                                -- todo: add set
                                name = "Suppress Expirimental Feature Prompt",
                                desc = "This will remove the warning on load when Action Cam is enabled."
                            }
                        }
                    },
                    motionSicknessMessage = {
                        type = "group",
                        name = "Action Cam Disabled",
                        order = 2,
                        inline = true,
                        hidden = addon.cameraCharacterCenteringDisabled,
                        args = {
                            message1 = {
                                type = "description",
                                order = 1,
                                name = "To enable Action Cam you must"
                            },
                            message2 = {
                                type = "execute",
                                order = 2,
                                width = "double",
                                name = "Disable Camera Character Centering",
                                func = function() C_CVar.SetCVar("CameraKeepCharacterCentered", "0") end
                            },
                            message3 = {
                                type = "description",
                                order = 3,
                                name = "which is enabled by default to prevent motion sickness in some users."
                            }
                        }
                    },
                    dynamicPitch = {
                        type = "group",
                        name = "Dynamic Pitch",
                        hidden = addon.cameraCharacterCenteringEnabled,
                        inline = true,
                        order = 2,
                        args = {}
                    },
                    headMovement = {
                        type = "group",
                        name = "Head Movement",
                        hidden = addon.cameraCharacterCenteringEnabled,
                        inline = true,
                        order = 3,
                        args = {}
                    },
                    targetFocus = {
                        type = "group",
                        name = "Target Focus",
                        hidden = addon.cameraCharacterCenteringEnabled,
                        inline = true,
                        order = 4,
                        args = {
                            enemyEnable = {
                                type = "toggle"
                            },
                            interactEnable = {
                                type = "toggle"
                            }
                        }
                    },
                    toggleDefaults = {
                        type = "execute",
                        name = function()
                            if (previousSettings.actionCam == nil) then
                                return "Defaults"
                            else
                                return "Undo"
                            end
                        end,
                        hidden = addon.cameraCharacterCenteringEnabled,
                        func = function() addon:toggleActionCamDefaults() end,
                        order = 99
                    }
                }
            }
        }
    }
    
    local actionCamArgs = options.args.actionCam.args

    -- actionCam CVars
    for index, cVar in pairs(actionCamCVars) do
        local groupName = nil
        for group, setting in pairs(actionCamArgs) do
            if (strfind(cVar, capitalize(group)) ~= nil) then
                groupName = group
                break
            end
        end

        if (groupName == nil) then
            groupName = "general"
        end

        local var = unCapitalize(cVar:gsub("test_camera", ""):gsub(capitalize(groupName), ""))
        local name = capitalize(splitCamelCase(var == "" and groupName or var))
        actionCamArgs[groupName].args[var] = deepMerge(
            {
                name = name,
                type = "input",
                order = 50,
                hidden = addon.cameraCharacterCenteringEnabled,
                get = function(info)
                    local CVar = 'test_camera' .. capitalize(groupName:gsub("general", "")) .. capitalize(info[#info])

                    if (info.type == 'toggle') then
                        return C_CVar.GetCVar(CVar) == "1" and true or false
                     else
                        return C_CVar.GetCVar(CVar)
                     end
                end,
                set = function(info, value)
                    local CVar = 'test_camera' .. capitalize(groupName:gsub("general", "")) .. capitalize(info[#info])
                    
                    if (type(value) == 'boolean') then
                        value = value and 1 or 0 -- convert to string
                    end

                    C_CVar.SetCVar(CVar, value)
                    settings.actionCam[CVar] = value
                end,
            },
            actionCamArgs[groupName].args[var] or {}
        )
    end

    -- actionCam commands
    for groupName, group in pairs(actionCamCommandOptions) do
        actionCamArgs[groupName].args.commands = {
            type = "group",
            name = "Commands",
            inline = true,
            hidden = addon.cameraCharacterCenteringEnabled,
            order = 99,
            args = {}
        }

        for index, command in pairs(group) do
            actionCamArgs[groupName].args.commands.args[command] = {
                type = "execute",
                name = capitalize(splitCamelCase(command)),
                func = function()
                    ConsoleExec("ActionCam " .. command)
                    addon:storeActionCamSettings()
                end
            }
        end
    end

    -- standing distances
    local standingDistances = options.args.general.args.standingDistances
    for race in pairs(races) do
        standingDistances.args[standingArgKey(race)] = merge(distanceOption(), {
            name = race,
            hidden = function() return (not showOtherRaces) and ((playerRace ~= race) and (playerRace ~= "Worgen" or race ~= "Human")) end
        })
    end
    local playerStandingArgKey = playerRace:gsub("^.", string.lower):gsub(" ", "") .. 'Distance'
    standingDistances.args[playerStandingArgKey].order = 1
    if (playerRace == "Worgen") then
        options.args.general.args.standingDistances.args.humanDistance.order = 2
    end

    -- stand by behavior
    if (xpac >= xpacs.sl) then
        options.args.general.args.standBy.args.standByBehavior.values.maxDistance = "Zoom to max distance"
    end

    return options
end

-- commands
local yellow = "cffffff00"
local colorStart = "\124"
local colorEnd = "\124r"
SLASH_AC1 = "/ac"
SlashCmdList["AC"] = function(arg)
    if arg == "toggle" then
        addon:toggleStandBy()
    elseif (arg == "standby") then
        addon:enterStandBy()
    elseif (arg == "resume") then
        addon:exitStandBy()
    elseif (arg == "settings") then
        InterfaceOptionsFrame_Show()
        InterfaceOptionsFrame_OpenToCategory("Auto-Camera")
    else
        print(colorStart .. yellow .. "Auto-Camera console commands:" .. colorEnd)
        print("/ac toggle       " .. colorStart .. yellow .. "toggles stand-by mode on/off" .. colorEnd)
        print("/ac standby    " .. colorStart .. yellow .. "enters stand-by mode" .. colorEnd)
        print("/ac resume     " .. colorStart .. yellow .. "exits stand-by mode" .. colorEnd)
        print("/ac settings    " .. colorStart .. yellow .. "opens Auto-Camera settings" .. colorEnd)
    end
end

-- events
local function OnEvent(self, event, ...)
    addon[event](self, event, ...)
end

function addon:PET_BATTLE_OPENING_START()
    IN_PET_BATTLE = true
end

function addon:PET_BATTLE_CLOSE()
    IN_PET_BATTLE = false
    if addon:isRunning() then
        addon:autoZoom()
    end
end

function addon:ENCOUNTER_START()
    IN_ENCOUNTER = true
end

function addon:ENCOUNTER_END()
    IN_ENCOUNTER = false
    if addon:isRunning() then
        addon:autoZoom()
    end
end

function addon:PLAYER_ENTERING_WORLD()
    local mapId = C_Map.GetBestMapForUnit("player")
    if (mapId == nil) then return end -- TODO what do when this happens?
    local x, y = C_Map.GetPlayerMapPosition(mapId, "player")
    if x == nil and y == nil then -- if in an instance
        local _, instanceType = GetInstanceInfo()
        IN_RAID = instanceType == "raid"
        IN_DUNGEON = instanceType == "raid"
    end
end

function addon:BARBER_SHOP_OPEN()
    IN_BARBER_SHOP = true
end

function addon:BARBER_SHOP_CLOSE()
    IN_BARBER_SHOP = false

    if (addon:isRunning()) then
        addon:autoZoom()
    end
end

-- todo> necessary?
function addon:VARIABLES_LOADED()
end

local f = CreateFrame("Frame")
f:RegisterEvent("PET_BATTLE_OPENING_START")
f:RegisterEvent("PET_BATTLE_CLOSE")
f:RegisterEvent("ENCOUNTER_START")
f:RegisterEvent("ENCOUNTER_END")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("BARBER_SHOP_OPEN")
f:RegisterEvent("BARBER_SHOP_CLOSE")
f:RegisterEvent("VARIABLES_LOADED")
f:SetScript("OnEvent", OnEvent)
