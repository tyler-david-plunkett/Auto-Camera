local addonName, vars = ...
ActionCamera = LibStub("AceAddon-3.0"):NewAddon(addonName)
local addon = ActionCamera
local AUTO_CAMERA_ENABLED = true -- todo> make this a setting
local IN_PET_BATTLE = false
local previousCameraZoom = GetCameraZoom()
local deltaTime = 0.1
local playerRace = UnitRace("player")
local races = set {"Human", "Dwarf", "Night Elf", "Gnome", "Draenei", "Worgen", "Pandaren", "Orc", "Undead", "Tauren", "Troll", "Blood Elf", "Goblin", "Pandaren", "Void Elf", "Lightforged Draenei", "Dark Iron Dwarf", "Kul Tiran", "Mechagnome", "Nightborne", "Highmountain Tauren", "Mag'har Orc", "Zandalari Troll", "Vulpera"}
races[playerRace] = true -- adds player race if it's missing from race set
local defaults = {
	global = {
		exitView = 1,
		petBattleView = 1,
		humanDistance = 3.5,
		worgenDistance = 4.6,
		ridingDistance = 8.5,
		eliteDistance = 8.5,
		bossDistance = 50
	}
}
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
end

function addon:OnEnable()
-- Called when the addon is enabled
end

function addon:OnDisable()
-- Called when the addon is disabled
end

-- helper functions
function toggleAutoCamera()
	if (AUTO_CAMERA_ENABLED) then
		AUTO_CAMERA_ENABLED = false
	else
		AUTO_CAMERA_ENABLED = true
		autoZoom()
	end
end

function autoZoom()
	local targetZoom
	local currentCameraZoom = GetCameraZoom()
	local unit
	local enemyCount = 0

	if (isWorgenForm()) then
		targetZoom = settings.worgenDistance
	else
		targetZoom = settings.humanDistance
	end
	
	if (
		AuraUtil.FindAuraByName("Running Wild", "player") == nil and
		(IsMounted("player") or UnitInVehicle("player"))
	) then
		targetZoom = settings.ridingDistance
	end

	local unitCount = 0
	for i, unit in ipairs(units) do
		local unitClassification = UnitClassification(unit)
		local unitLevel = UnitLevel(unit)
		if (
			not UnitIsDead(unit) and
			UnitCanAttack("player", unit) and
			CheckInteractDistance(unit, 1) and
			(unit == 'target' or UnitGUID('target') ~= UnitGUID(unit)) -- if unit is target or a unit with nameplate that isn't the target (avoids counting target twice)
		) then
			unitCount = unitCount + 1
			if (
				(unitClassification == "worldboss" or
				(unitClassification == "elite" and UnitLevel(unit) == -1)) -- and
				-- targetZoom < 50 -- todo> is this necessary?
			) then targetZoom = settings.bossDistance
			elseif (
				unitClassification == "elite" -- and
				-- targetZoom < 8.5 -- todo> is this necessary
			) then targetZoom = settings.eliteDistance end
		end
	end

	local countDistance = unitCount * 4
	if (targetZoom < countDistance) then targetZoom = countDistance end

	-- local distanceDiff = distanceIndexedCameraZoom[distancePartition] - currentCameraZoom
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
		C_Timer.After(deltaTime, autoZoom)
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

-- options
function addon:options()
	local options = {
		type = 'group',
		set = function(info, val) settings[info[#info]] = val end,
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
						name = "Standing Distances by Race",
						args = {} -- dynamically populated below
					},
					contexturalDistances = {
						type = "group",
						inline = true,
						order = 2,
						name = "Contextual Distances",
						args = {
							ridingDistance = merge(distanceOption(), {
								name = 'Riding',
								desc = 'On mount or in a vehicle'
							}),
							eliteDistance = merge(distanceOption(), {
								name = 'Elite Combat'
							}),
							bossDistance = merge(distanceOption(), {
								name = 'Boss Combat'
							}),
						}
					},
					misc = {
						type = "group",
						inline = true,
						order = 3,
						name = "Miscellaneous",
						args = {
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
		standingDistances.args[race:lower() .. 'Distance'] = merge(distanceOption(), {
			name = race
		})
	end
	standingDistances.args[playerRace:lower() .. 'Distance'].order = 1
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

if (AUTO_CAMERA_ENABLED) then
	autoZoom()
end

-- events
local function OnEvent(self, event, ...)
	if event == "PET_BATTLE_OPENING_START" then
		IN_PET_BATTLE = true
	elseif event == "PET_BATTLE_CLOSE" then
		IN_PET_BATTLE = false
		if addon:isRunning() then
			autoZoom()
		end
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PET_BATTLE_OPENING_START")
f:RegisterEvent("PET_BATTLE_CLOSE")
f:SetScript("OnEvent", OnEvent)