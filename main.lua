local addonName, vars = ...
ActionCamera = LibStub("AceAddon-3.0"):NewAddon(addonName)
local addon = ActionCamera
local AUTO_CAMERA_ENABLED = false
local IN_PET_BATTLE = false
local previousCameraZoom = GetCameraZoom()
local deltaTime = 0.1
local playerRace = UnitRace("player")
local playerStandingArgKey = standingArgKey(playerRace)
local showOtherRaces = false
local races = set {"Human", "Dwarf", "Night Elf", "Gnome", "Draenei", "Worgen", "Pandaren", "Orc", "Undead", "Tauren", "Troll", "Blood Elf", "Goblin", "Void Elf", "Lightforged Draenei", "Dark Iron Dwarf", "Kul Tiran", "Mechagnome", "Nightborne", "Highmountain Tauren", "Mag'har Orc", "Zandalari Troll", "Vulpera"}
races[playerRace] = true -- adds player race if it's missing from race set
local defaults = {
    global = {
        enabledOnLoad = false,
        exitView = 1,
        petBattleView = 1,
        ridingDistance = 8.5,
        normalEnemyDistance = 4,
        eliteEnemyDistance = 4,
        bossEnemyDistance = 50
    }
}

for race in pairs(set {"Worgen"}) do
    defaults.global[standingArgKey(race)] =  4.6
end

for race in pairs(set {"Night Elf", "Nightborne"}) do
    defaults.global[standingArgKey(race)] =  4
end

for race in pairs(set {"Draenei", "Pandaren" ,"Orc", "Troll", "Mag'har Orc", "Zandalari Troll", "Lightforged Draenei"}) do
    defaults.global[standingArgKey(race)] =  4.5
end

for race in pairs(set {"Human", "Dwarf", "Undead", "Blood Elf" ,"Void Elf", "Dark Iron Dwarf"}) do
    defaults.global[standingArgKey(race)] = 3.5
end

for race in pairs(set {"Gnome", "Goblin", "Mechagnome", "Vulpera"}) do
    defaults.global[standingArgKey(race)] = 2
end

for race in pairs(set {"Tauren", "Kul Tiran", "Highmountain Tauren"}) do
    defaults.global[standingArgKey(race)] = 5.2
end

local settings = defaults.global
local units = {}
units[1] = 'target'
for i = 1, 10 do
    units[i + 1] = 'nameplate' .. i
end

BINDING_HEADER_AUTO_CAMERA = "Auto-Camera"
BINDING_NAME_TOGGLE_AUTO_CAMERA = "Toggle On/Off"

function addon:isRunning() 
    return AUTO_CAMERA_ENABLED and not IN_PET_BATTLE
end

function addon:RefreshConfig()
    settings = addon.db.global
    addon.settings = settings
    for key, value in pairs(defaults.global) do
        if settings[key] == nil then
            settings[key] = deepCopy(value)
        end
    end
end

-- addon hook callback functions
function addon:OnInitialize()
    local options = addon:options()
    addon.db = LibStub("AceDB-3.0"):New("AutoCameraDB", defaultSettings, true)
    addon:RefreshConfig()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options, nil)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName, nil, "general")
    options.args.globals = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db)
    AUTO_CAMERA_ENABLED = settings.enabledOnLoad
    if (AUTO_CAMERA_ENABLED) then
        addon:autoZoom()
    end
end

-- helper functions
function toggleAutoCamera()
    if (AUTO_CAMERA_ENABLED) then
        AUTO_CAMERA_ENABLED = false
    else
        AUTO_CAMERA_ENABLED = true
        addon:autoZoom()
    end
end

function addon:autoZoom()
    local targetZoom
    local currentCameraZoom = GetCameraZoom()
    local unit
    local enemyCount = 0

    targetZoom = settings[playerStandingArgKey]
    if (playerRace == "Worgen" and not isWorgenForm()) then
        targetZoom = settings.humanDistance
    end
    
    if (
        AuraUtil.FindAuraByName("Running Wild", "player") == nil and
        (IsMounted("player") or UnitInVehicle("player"))
    ) then
        targetZoom = settings.ridingDistance
    end

    local enemyPackDistance = 0
    for i, unit in ipairs(units) do
        local unitClassification = UnitClassification(unit)
        local unitLevel = UnitLevel(unit)
        if (
            not UnitIsDead(unit) and
            UnitCanAttack("player", unit) and
            CheckInteractDistance(unit, 1) and
            (unit == 'target' or UnitGUID('target') ~= UnitGUID(unit)) -- if unit is target or a unit with nameplate that isn't the target (avoids counting target twice)
        ) then
            enemyPackDistance = enemyPackDistance + settings[enemyArgKey(unit)]
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
        if not AUTO_CAMERA_ENABLED then
            SetView(settings.exitView)
        elseif IN_PET_BATTLE then
            SetView(settings.petBattleView)
        end
    end

    previousCameraZoom = currentCameraZoom
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
        max = 50,
        step = 0.1,
        order = 3
    }
end

function addon:defaultStandingDistances()
    settings = defaults.global
end

-- options
function addon:options()
    local options = {
        type = 'group',
        set = function(info, val)
            settings[info[#info]] = val
        end,
        get = function(info) return settings[info[#info]] end,
        args = {
            general = {
                type = "group",
                name = "General",
                args = {
                    standingDistances = {
                        type = "group",
                        inline = true,
                        order = 1,
                        name = "Standing Camera Distances by Race",
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
                            },
                            restoreDefaults = {
                                type = "execute",
                                name = "Restore Defaults",
                                func = function() addon:defaultStandingDistances() end,
                                order = 100
                            }
                        }
                    },
                    contextualDistances = {
                        type = "group",
                        inline = true,
                        order = 2,
                        name = "Contextual Camera Distances",
                        args = {
                            ridingDistance = merge(distanceOption(), {
                                name = 'Riding',
                                desc = 'Camera distance when on a mount or in a vehicle',
                                order = 1
                            }),
                            normalEnemyDistance = merge(distanceOption(), {
                                name = 'Per Normal Enemy',
                                order = 2
                            }),
                            eliteEnemyDistance = merge(distanceOption(), {
                                name = 'Per Elite Enemy',
                                order = 3
                            }),
                            bossEnemyDistance = merge(distanceOption(), {
                                name = 'Per Boss Enemy',
                                order = 4
                            }),
                        }
                    },
                    misc = {
                        type = "group",
                        inline = true,
                        order = 3,
                        name = "Miscellaneous",
                        args = {
                            enabledOnLoad = {
                                type = "toggle",
                                name = "Enabled on Start-Up",
                                desc = "Controls if automatic camera zooming should begin on start-up"
                            },
                            exitView = merge(viewOption(), {
                                type = 'range',
                                min = 1,
                                max = 5,
                                step = 1,
                                name = 'Exit View',
                                desc = 'The camera view to go to when toggling Auto-Camera off'
                            }),
                            petBattleView = merge(viewOption(), {
                                type = 'range',
                                min = 1,
                                max = 5,
                                step = 1,
                                name = 'Pet Battle View',
                                desc = 'The camera view to go to during a pet battle.'
                            })
                        }
                    }
                }
            }
        }
    }

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
    return options
end

-- commands
local yellow = "cffffff00"
local colorStart = "\124"
local colorEnd = "\124r"
SLASH_AC1 = "/ac"
SlashCmdList["AC"] = function(arg)
    if arg == "toggle" then
        toggleAutoCamera()
    else
        print(colorStart .. yellow .. "Auto-Camera console commands:" .. colorEnd)
        print("/ac toggle    " .. colorStart .. yellow .. "toggles Auto-Camera on/off" .. colorEnd)
    end
end

-- events
local function OnEvent(self, event, ...)
    if event == "PET_BATTLE_OPENING_START" then
        IN_PET_BATTLE = true
    elseif event == "PET_BATTLE_CLOSE" then
        IN_PET_BATTLE = false
        if addon:isRunning() then
            addon:autoZoom()
        end
    elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
    end
end

function addon:INSTANCE_ENCOUNTER_ENGAGE_UNIT()
end

local f = CreateFrame("Frame")
f:RegisterEvent("PET_BATTLE_OPENING_START")
f:RegisterEvent("PET_BATTLE_CLOSE")
f:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
f:SetScript("OnEvent", OnEvent)
