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

function standingArgKey(race)
    return race:gsub("^.", string.lower):gsub(" ", "") .. 'Distance'
end
