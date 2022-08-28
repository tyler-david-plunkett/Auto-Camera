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

function assign(target, source)
    table.foreach(source, function(key, value)
        target[key] = value
    end)
end

function set(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

function merge(target, source, prune)
    if (prune == nil) then prune = false end
    for key, value in pairs(source) do
        if (not prune or target[key] ~= nil) then
            target[key] = value
        end
    end
    return target
end

function deepMerge(target, source, prune)
    if (prune == nil) then prune = false end
    for key, value in pairs(source) do
        if (not prune or target[key] ~= nil) then
            if (type(value) == "table") then
                target[key] = deepMerge(target[key] or {}, value)
            else
                target[key] = value
            end
        end
    end
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

function getOrderOfMagnitude(value)
    return 10^math.floor(math.log(value) / math.log(10))
end

-- join elements of a table as a string
function joinTable(tbl, glue)
    glue = glue or ""

    local str = ""

    for key, value in pairs(tbl) do
        str = str .. (str ~= "" and glue or "") .. value
    end

    return str
end

-- recursively print a table
function printTable(tbl, depth)
    local depth = depth or 0;
    
    for key, value in pairs(tbl) do
        local indent = ""

        for i = 0, depth do
            indent = indent .. "  "
        end
        
        if (type(value) == 'table') then
            print(indent .. key .. ': {')
            printTable(value, depth + 1)
            print(indent .. '}')
        else
            print (indent .. key .. ': ' .. value)
        end
    end
end
