function deepCopy(tree)
    if not tree then return nil
    elseif type(tree) == "table" then
        local branch = {}
        
        for key, value in pairs(tree) do
            branch[key] = deepCopy(value)
        end
        
        return branch
    else
        return tree
    end
end

function set (list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

function merge(target, source)
    for key, value in pairs(source) do target[key] = value end
    return target
end

function camelCase(str)
    return str:gsub("^.", string.lower):gsub(" ", "")
end

function standingArgKey(race)
    return camelCase(race) .. 'Distance'
end

function enemyArgKey(unit)
	if (
		(unitClassification == "worldboss" or
		(unitClassification == "elite" and UnitLevel(unit) == -1))
	) then
		return "bossEnemyDistance"
	elseif (
		unitClassification == "elite"
	) then
		return "bossEnemyDistance"
	else
		return "normalEnemyDistance"
	end
end
