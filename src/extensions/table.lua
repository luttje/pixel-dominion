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
--- @param table table
--- @param value any
--- @return boolean, number|nil # Whether the table contains the value, and the index of the value.
function table.HasValue(table, value)
	for i, v in pairs(table) do
		if (v == value) then
			return true, i
		end
	end

	return false, nil
end
