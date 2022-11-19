local _ , race = UnitRace("player")
local playerModelFrame = CreateFrame("PlayerModel", nil, UIParent)
local ModelFileIDs = {[1000764]="Human 2", [1011653]="Human 1", [307454]="Worgen 1", [307453]="Worgen 2", [4220448]="Visage 2", [4207724]="Dracthyr", [4395382]="Visage 1" }

function getPlayerModelName()
	playerModelFrame:SetUnit("player")
	return ModelFileIDs[playerModelFrame:GetModelFileID()]
end
