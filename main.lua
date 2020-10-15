-- todo define zoom event behavior
local addonName, addon = ...
local AutoCamera = addon
local AUTO_CAMERA_ENABLED = true -- todo> make this a setting
local previousCameraZoom = GetCameraZoom()
local deltaTime = 0.1 -- deltaTime
local units = {}
local exitView = 2 -- todo> setting

BINDING_HEADER_AUTO_CAMERA = "Auto-Camera"
BINDING_NAME_TOGGLE_AUTO_CAMERA = "Toggle On/Off"

units[1] = 'target'
for i = 1, 10 do
	units[i + 1] = 'nameplate' .. i
end
 
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
		targetZoom = 4.6
	else
		targetZoom = 3.5
	end
	
	if (
		AuraUtil.FindAuraByName("Running Wild", "player") == nil and
		(IsMounted("player") or UnitInVehicle("player"))
	) then
		targetZoom = 8.5
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
				(unitClassification == "elite" and UnitLevel(unit) == -1)) and
				targetZoom < 50
			) then targetZoom = 50
			elseif (
				unitClassification == "elite" and
				targetZoom < 8.5
			) then targetZoom = 8.5 end
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

	if (AUTO_CAMERA_ENABLED) then
		C_Timer.After(deltaTime, autoZoom)
	else
		MoveViewInStop()
		MoveViewOutStop()
		SetView(exitView)
	end

	previousCameraZoom = currentCameraZoom
end

-- commands
SLASH_AC1 = "/ac"
SlashCmdList["AC"] = function(msg)
	toggleAutoCamera()
end

if (AUTO_CAMERA_ENABLED) then
	autoZoom()
end
