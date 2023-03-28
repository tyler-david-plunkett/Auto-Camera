local addonName, T = ...
local _ , race = UnitRace("player")
local playerModelFrame = CreateFrame("PlayerModel", nil, UIParent)
local ModelFileIDs = {[1000764]="Human 2", [1011653]="Human 1", [307454]="Worgen 1", [307453]="Worgen 2", [4220448]="Visage 2", [4207724]="Dracthyr", [4395382]="Visage 1" }

function getPlayerModelName()
	return ModelFileIDs[playerModelFrame:GetModelFileID()]
end

-- todo> playerModelFrame:RefreshUnit() -- https://www.wowinterface.com/forums/showthread.php?t=48394
T.playerModelFrame = playerModelFrame
playerModelFrame:SetUnit("player")
playerModelFrame:SetScript("OnEvent", function(self)
	self:SetUnit("player")
end)
playerModelFrame:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player")
