--- Merges the contents of a table into another table.
--- @param target table
--- @param source table
--- @return table # The target table
function table.Merge(target, source)
	for key, value in pairs(source) do
		target[key] = value
	end

	return target
end

--- Copies the contents of a table into a new table recursively.
--- This is useful to prevent modifying the original table accidentally.
--- @param source table
--- @return table # The new table
function table.Copy(source)
	local target = {}

	for key, value in pairs(source) do
		if (type(value) == 'table') then
			target[key] = table.Copy(value)
		else
			target[key] = value
		end
	end

	return target
end

--- Checks if a table contains a value.
--- @param source table
--- @param value any
--- @return boolean, number|nil # Whether the table contains the value, and the index of the value.
function table.HasValue(source, value)
    for i, v in pairs(source) do
        if (v == value) then
            return true, i
        end
    end

    return false, nil
end

--- Returns only the keys of a table.
--- @param source table
--- @return table # The keys of the table
function table.Keys(source)
    local keys = {}

    for key, _ in pairs(source) do
        table.insert(keys, key)
    end

    return keys
end

--- Returns only the values of a table.
--- @param source table
--- @return table # The values of the table
function table.Values(source)
	local values = {}

	for _, value in pairs(source) do
		table.insert(values, value)
	end

	return values
end
