-- todo define zoom event behavior
ConsoleExec("scriptErrors 1") -- todo remove
ConsoleExec("cameraZoomSpeed 50")
local addonName, addon = ...
local DynamicZoom = addon
local AUTO_ZOOM_ENABLED = true

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

function getMaxDistance(unit)
	for index, boundry in pairs(boundries) do
		if (IsSpellInRange(boundry.spellName, unit) == 1) then
			return boundry.range
		end
	end

	return 0
end

function autoZoom()
	local targetZoom = 0
	local currentCameraZoom = GetCameraZoom()
	local spellDistance
	local interactDistance
	local unit

	for i = 1, 40 do -- todo are nameplates dynamically in order?
		unit = 'nameplate' .. i

		-- if UnitExists(unit) ~= true then break end

		if UnitIsDead(unit) == false and UnitCanAttack("player", unit) then
			spellDistance = getMaxDistance(unit)
			interactDistance = getInteractDistance(unit) -- [1,4] < 10; [2, 3, 5] > 10 (not useful if the spec has a range 10 spell)

			-- todo stealth limits IsSpellInRange
			if spellDistance ~= nil and targetZoom < spellDistance then targetZoom = spellDistance end
			-- if interactDistance ~= nil and targetZoom < interactDistance then targetZoom = interactDistance end
		end
	end
	
	if (targetZoom < 4.5) then
		if (IsMounted("player") and AuraUtil.FindAuraByName("Running Wild", "player") == nil) then
			targetZoom = 8.5
		else
			if (isWorgenForm()) then
				targetZoom = 4.5
			else
				targetZoom = 3.5
			end
		end
	end
	
	-- local distanceDiff = distanceIndexedCameraZoom[distancePartition] - currentCameraZoom
	local distanceDiff = targetZoom - currentCameraZoom
	
	-- todo fix over-zoom bug
	if (abs(distanceDiff) > 0.05) then
		if (distanceDiff >= 0) then
			MoveViewInStop()
			MoveViewOutStart()
		else
			MoveViewOutStop()
			MoveViewInStart()
		end
	else
		MoveViewInStop()
		MoveViewOutStop()
	end
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

local ticker = C_Timer.NewTicker(0.01, autoZoom)
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
-- CameraZoomOut(40) -- 28 total
-- GetCameraZoom()
-- UnitExists("target")

-- distances
-- human 3.5
-- worgen 4.5
