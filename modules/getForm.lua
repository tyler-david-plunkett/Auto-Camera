local _ , race = UnitRace("player")
local CombatTracker = 1
local worgenFrame = CreateFrame("PlayerModel", nil, UIParent)
local ModelFileIDs = {[1000764]="Human Female", [1011653]="Human Male"}

function isWorgenForm()
	worgenFrame:SetUnit("player")
	local NDA_ModelName = worgenFrame:GetModelFileID()
	return race ~= "Worgen" or ModelFileIDs[NDA_ModelName] == nil
end
