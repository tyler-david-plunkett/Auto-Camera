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

function assign (target, source)
    table.foreach(source, function(key, value)
        target[key] = value
    end)
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

function splitCamelCase(str)
	return str:gsub("%u", " %1")
end

function capitalize(str)
    return str:gsub("^%l", string.upper)
end

function unCapitalize(str)
    return str:gsub("^%u", string.lower)
end
