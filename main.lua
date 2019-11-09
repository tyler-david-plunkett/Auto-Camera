ConsoleExec("scriptErrors 1")
ConsoleExec("cameraZoomSpeed 10")
print("Dynamic Zoom Init Start")
local addonName, addon = ...
local DynamicZoom = addon
local AUTO_ZOOM_ENABLED = true
local DEBUG = false

local boundries = {}
-- local distanceIndexedCameraZoom = {4.5, 8.5, 28.5}
local prevDistancePartition

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

function getMaxDistance(unit)
	for index, boundry in pairs(boundries) do
		if (IsSpellInRange(boundry.spellName, unit) == 1) then
			return boundry.range
		end
	end

	return 100
end

function autoZoom()
	local currentCameraZoom = GetCameraZoom()
	local spellDistance
	if UnitExists("target") and UnitIsDead("target") == false and UnitCanAttack("player", "target") then
		spellDistance = getMaxDistance("target")
		interactDistance = getInteractDistance("target") -- 1,4 <10; 2,3,5 >10 (not useful if the spec has a range 10 spell)
		-- print(interactDistance)
	end

	if (spellDistance == nil or spellDistance < 4.5) then
		if (IsMounted("player") and AuraUtil.FindAuraByName("Running Wild", "player") == nil) then
			spellDistance = 8.5
		else
			if (isWorgenForm()) then
				spellDistance = 4.5
			else
				spellDistance = 3.5
			end
		end
	end
	
	-- local distanceDiff = distanceIndexedCameraZoom[distancePartition] - currentCameraZoom
	local distanceDiff = spellDistance - currentCameraZoom
	
	-- todo fix over-zoom bug
	if (prevSpellDistance ~= spellDistance and abs(distanceDiff) > 0.2) then
		if (distanceDiff >= 0) then
			CameraZoomOut(distanceDiff)
		else
			CameraZoomIn(distanceDiff * -1)
		end
	end
	prevSpellDistance = spellDistance
end

-- remove
function printNameplatePositions()
	print ("printNameplatePositions")
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

-- SlashCmdList["/autoZoom"] = function()
	-- AUTO_ZOOM_ENABLED = !AUTO_ZOOM_ENABLED
	-- if (AUTO_ZOOM_ENABLED)
		-- autoZoom()
-- end
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

local ticker = C_Timer.NewTicker(DEBUG and 1 or 0.1, autoZoom)
-- local ticker = C_Timer.NewTicker(DEBUG and 1 or 2, printNameplatePositions)
-- autoZoom()
-- print("OnUpdate")

-- /run a, b, c = WorldFrame:GetChildren()
-- /run ufc1, ufc2, ufc3, ufc4, ufc5, ufc6 = child3.UnitFrame:GetChildren()
-- /run print(ufc1)
-- /run point, relativeTo, relativePoint, xOfs, yOfs = WorldFrame:GetPoint()

print("Dynamic Zoom Init End")

-- close
-- 5
-- 4
-- far

-- events
-- UPDATE_SHAPESHIFT_FORM

-- functions
-- CameraZoomOut(40) -- 28 total
-- GetCameraZoom()
-- UnitExists("target")

-- distances
-- human 3.5
-- worgen 4.5
