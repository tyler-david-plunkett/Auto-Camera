-- todo define zoom event behavior
local addonName, addon = ...
local DynamicZoom = addon
local AUTO_ZOOM_ENABLED = true
local previousCameraZoom = GetCameraZoom()
local deltaTime = 0.01 -- deltaTime
local units = {}

units[1] = 'target'
-- for i = 2, 10 do
-- 	units[i] = 'nameplate' .. i
-- end

local boundries = {}

function tableLength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

function getInteractDistance(unit)
	if (CheckInteractDistance("target", 3)) then
		return 9.9
	elseif (CheckInteractDistance("target", 2)) then
		return 11.11
	elseif (CheckInteractDistance("target", 1)) then
		return 28
	end
end

function getSpellDistance(unit)
	for index, boundry in pairs(boundries) do
		if (IsSpellInRange(boundry.spellName, unit) == 1) then
			return boundry.range
		end
	end

	return 0
end

function getDistance(unit)
	if UnitIsDead(unit) == true or UnitCanAttack("player", unit) == false then return nil end

	spellDistance = getSpellDistance(unit) or 0
	interactDistance = getInteractDistance(unit) or 0 -- [1,4] < 10; [2, 3, 5] > 10 (not useful if the spec has a range 10 spell)

	-- todo stealth limits IsSpellInRange
	if spellDistance < interactDistance then
		return spellDistance
	else
		return interactDistance
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
	
	if (IsMounted("player") and AuraUtil.FindAuraByName("Running Wild", "player") == nil) then
		targetZoom = 8.5
	end

	for i, unit in ipairs(units) do
		local unitClassification = UnitClassification(unit)
		local unitLevel = UnitLevel(unit)
		if (UnitIsDead(unit) == false and UnitCanAttack("player", unit) == true) then
			if (
				unitClassification == "worldboss" or 
				(unitClassification == "elite" and UnitLevel(unit) == -1)
			) then targetZoom = 50 end
		end
	end

	-- local distanceDiff = distanceIndexedCameraZoom[distancePartition] - currentCameraZoom
	local distanceDiff = targetZoom - currentCameraZoom
	
	-- todo fix over-zoom bug
	if (abs(distanceDiff) > 0.1) then
		local cameraZoomSpeed = distanceDiff / tonumber(GetCVar("cameraZoomSpeed"))
		if (cameraZoomSpeed < 0) then cameraZoomSpeed = cameraZoomSpeed * -1 end
		if (distanceDiff > 0) then
			MoveViewInStop()
			MoveViewOutStart(cameraZoomSpeed)
		else
			MoveViewOutStop()
			MoveViewInStart(cameraZoomSpeed)
		end
	else
		MoveViewInStop()
		MoveViewOutStop()
	end

	if (AUTO_ZOOM_ENABLED) then
		C_Timer.After(deltaTime, autoZoom)
	else
		MoveViewInStop()
		MoveViewOutStop()
	end

	previousCameraZoom = currentCameraZoom
end

-- remove
function printNameplatePositions()
	for i, frame in pairs({WorldFrame:GetChildren()}) do
		local name = frame:GetName()
		if name and strmatch(name, "NamePlate") then
			-- unitFrame = frame.UnitFrame
			print(frame:GetPoint())
			-- print()
			-- point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
			-- print(point, relativeTo, relativePoint, xOfs, yOfs)
			local unitFrame = frame:GetChildren()
			local unit = unitFrame and unitFrame:GetAttribute("unit")
			if unitFrame and unit then
				-- print (unit)
			end
		end
	end
end

-- event handlers
local CoreEvents = {}

local function EventHandler(self, event, ...)
	CoreEvents[event](event, ...)
end

function CoreEvents:NAME_PLATE_UNIT_ADDED(...)
	-- print("name plate unit added")
	-- local unitid = ...
	-- local plate = C_NamePlate.GetNamePlateForUnit(unitid);

	-- -- We're not going to theme the personal unit bar
	-- -- if plate and not UnitIsUnit("player", unitid) then
		-- local childFrame = plate:GetChildren()
		-- if childFrame then print(childFrame:GetTop()) end
		-- -- OnShowNameplate(plate, unitid)
	-- -- end

end

SLASH_DZ1 = "/dz"
SlashCmdList["DZ"] = function(msg)
	if (AUTO_ZOOM_ENABLED) then
		AUTO_ZOOM_ENABLED = false
	else
		AUTO_ZOOM_ENABLED = true
		autoZoom()
	end
end

local i = 1
for spellId, spellName in playerSpells() do
	local name, _, _, _, minRange, maxRange, _ = GetSpellInfo(spellName)
	
	if (minRange ~= 0 and minRange ~= nil) then
		local boundry = {}
		boundry.range = minRange
		boundry.type = "min"
		boundry.spellName = spellName
		boundries[i] = boundry
		i = i + 1
	end

	if (maxRange ~= nil) then
		local boundry = {}
		boundry.range = maxRange
		boundry.type = "max"
		boundry.spellName = spellName
		boundries[i] = boundry
		i = i + 1
	end

	-- print(name, minRange, maxRange)
end

table.sort(boundries, function (a, b) return a.range < b.range end)

-- for index, boundry in pairs(boundries) do
-- 	print(boundry.range)
-- end

if (AUTO_ZOOM_ENABLED) then
	autoZoom()
end
-- local ticker = C_Timer.NewTicker(2, printNameplatePositions)
-- autoZoom()
-- print("OnUpdate")

-- /run a, b, c = WorldFrame:GetChildren()
-- /run ufc1, ufc2, ufc3, ufc4, ufc5, ufc6 = child3.UnitFrame:GetChildren()
-- /run print(ufc1)
-- /run point, relativeTo, relativePoint, xOfs, yOfs = WorldFrame:GetPoint()

-- close
-- 5
-- 4
-- far

-- events
-- UPDATE_SHAPESHIFT_FORM

-- functions
-- UnitExists("target")

-- distances
-- human 3.5
-- worgen 4.6
