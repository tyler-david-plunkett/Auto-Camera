ConsoleExec("scriptErrors 1")
print("Dynamic Zoom Init Start")
local addonName, addon = ...
local DynamicZoom = addon
local AUTO_ZOOM_ENABLED = true
local DEBUG = false
local distanceIndexedCameraZoom = {4.5, 8.5, 28.5}
local prevDistancePartition

do
	do
	
	  -- https://us.battle.net/forums/en/wow/topic/6551965395
	  function iterateFlyout (state)
		while state.flyoutSlotIdx <= state.numFlyoutSlots do
		  local spellId, _, spellKnown, spellName = GetFlyoutSlotInfo(state.flyoutId, state.flyoutSlotIdx)
		  state.flyoutSlotIdx = state.flyoutSlotIdx + 1
		  if spellKnown then
			return spellId, spellName
		  end
		end
		state.slotIdx = state.slotIdx + 1
		state.currentIterator = iterateSlots
		return state:currentIterator()
	  end
	
	  -- https://us.battle.net/forums/en/wow/topic/6551965395
	  function iterateSlots (state)
		while state.slotIdx <= state.numSlots do
		  local spellBookItem = state.slotOffset + state.slotIdx
		  local spellName, spellSubtext = GetSpellBookItemName(spellBookItem, BOOKTYPE_SPELL)
		  local spellType, spellId = GetSpellBookItemInfo(spellBookItem, BOOKTYPE_SPELL)
		  if spellType == "SPELL" and not IsPassiveSpell(spellId) then
			state.slotIdx = state.slotIdx + 1
			return spellId, spellName, spellSubtext
		  elseif spellType == "FLYOUT" then
			local _, _, numFlyoutSlots, flyoutKnown = GetFlyoutInfo(spellId)
			if flyoutKnown then
			  state.flyoutId = spellId
			  state.flyoutSlotIdx = 1
			  state.numFlyoutSlots = numFlyoutSlots
			  state.currentIterator = iterateFlyout
			  return state:currentIterator()
			end
		  end
		  state.slotIdx = state.slotIdx + 1
		end
		state.tabIdx = state.tabIdx + 1
		state.currentIterator = iterateTabs
		return state:currentIterator()
	  end
	  
	  -- https://us.battle.net/forums/en/wow/topic/6551965395
	  function iterateTabs (state)
		while state.tabIdx <= state.numOfTabs do
		  local _, _, slotOffset, numSlots, _, offSpecID = GetSpellTabInfo(state.tabIdx)
		  if offSpecID ~= 0 then
			state.tabIdx = state.tabIdx + 1
		  else
			state.slotOffset = slotOffset
			state.numSlots = numSlots
			state.slotIdx = 1
			state.currentIterator = iterateSlots
			return state:currentIterator()
		  end
		end
		return nil
	  end
	  
	  -- https://us.battle.net/forums/en/wow/topic/6551965395
	  function dispatch(state)
		return state:currentIterator()
	  end
	
	  -- https://us.battle.net/forums/en/wow/topic/6551965395
	  function playerSpells()
		local state = {}
		state.tabIdx = 1
		state.numOfTabs = GetNumSpellTabs()
		state.currentIterator = iterateTabs
		return dispatch, state
	  end
	
	end

	function getDistancePartition(unit)
		if (CheckInteractDistance("target", 5)) then
			return 1
		elseif (CheckInteractDistance("target", 4)) then
			return 2
		end
		
		return 3
	end
	
	function tablelength(T)
		local count = 0
		for _ in pairs(T) do count = count + 1 end
		return count
	end

	function autoZoom()
		local currentCameraZoom = GetCameraZoom()
		local distancePartition
		if UnitExists("target") then
			distancePartition = getDistancePartition("target")
		else
			distancePartition = 1
		end
		
		local distanceDiff = distanceIndexedCameraZoom[distancePartition] - currentCameraZoom
		
		-- print(distanceDiff)
		if (prevDistancePartition ~= distancePartition and abs(distanceDiff) > 0.2) then
			if (distanceDiff >= 0) then
				CameraZoomOut(distanceDiff)
			else
				CameraZoomIn(distanceDiff * -1)
			end
		end
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
end

-- local ticker = C_Timer.NewTicker(DEBUG and 1 or 0.1, autoZoom)
-- local ticker = C_Timer.NewTicker(DEBUG and 1 or 2, printNameplatePositions)
-- autoZoom()
-- print("OnUpdate")

-- SlashCmdList["/autoZoom"] = function()
	-- AUTO_ZOOM_ENABLED = !AUTO_ZOOM_ENABLED
	-- if (AUTO_ZOOM_ENABLED)
		-- autoZoom()
-- end

local boundries = {}
local i = 1
for spellId, spellName in playerSpells() do
	local name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellName)
	
	if (minRange ~= 0 and minRange ~= nil) then
		local boundry = {}
		boundry.range = minRange
		boundry.type = "min"
		boundry.spellName = spellName
		boundries[i] = boundry
		i = i + 1
	end

	if (maxRange ~= 0 and maxRange ~= nil) then
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

for index, boundry in pairs(boundries) do
	print(boundry.range)
end

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
