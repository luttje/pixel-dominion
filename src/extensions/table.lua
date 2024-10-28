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

--- Appends the contents of a table into another table.
--- @param target table
--- @param source table
--- @return table # The target table
function table.Append(target, source)
	for _, value in pairs(source) do
		table.insert(target, value)
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

--- Shallow copy where only the first level of the table is copied.
--- This respects references to other tables.
--- @param source table
--- @return table # The new table
function table.ShallowCopy(source)
	local target = {}

	for key, value in pairs(source) do
		target[key] = value
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

--- Empties a table.
--- @param source table
function table.Empty(source)
	for key, _ in pairs(source) do
		source[key] = nil
	end
end

--- Finds the index of a value in a table.
--- @param source table
--- @param value any
--- @return number|nil # The index of the value
function table.IndexOf(source, value)
	for i, v in pairs(source) do
		if (v == value) then
			return i
		end
	end

	return nil
end

--- Returns a random value from a table.
--- @param source table
--- @return any # The random value
function table.Random(source)
	local keys = table.Keys(source)
	local randomKey = keys[math.random(1, #keys)]

	return source[randomKey]
end

--- Creates a stack from a table which provides push and pop operations.
--- @param source table
--- @return Stack # The stack
function table.Stack(source)
	--- @class Stack<T>
	--- @generic T : table
	local stack = {}

	--- Pushes a value to the stack.
	--- @param value any
	function stack:push(value)
		table.insert(source, value)
	end

	--- Pops a value from the stack.
	--- @return any # The popped value
    function stack:pop()
        return table.remove(source)
    end

    --- Peeks at the top value of the stack.
	--- @return any # The top value
    function stack:peek()
        return source[#source]
    end

    --- Returns the size of the stack.
	--- @return number # The size
    function stack:size()
        return #source
    end

    --- Checks if the stack is empty.
	--- @return boolean # Whether the stack is empty
	function stack:isEmpty()
		return #source == 0
	end

	return stack
end

--- Creates a queue from a table which provides enqueue and dequeue operations.
--- @param source table
--- @return Queue # The queue
function table.Queue(source)
    --- @class Queue<T>
	--- @generic T : table
	local queue = {}

	--- Enqueues a value to the queue.
	--- @param value any
	function queue:enqueue(value)
		table.insert(source, value)
	end

	--- Dequeues a value from the queue.
	--- @return any # The dequeued value
	function queue:dequeue()
		return table.remove(source, 1)
	end

	--- Peeks at the front value of the queue.
	--- @return any # The front value
	function queue:peek()
		return source[1]
	end

	--- Returns the size of the queue.
	--- @return number # The size
	function queue:size()
		return #source
	end

	--- Checks if the queue is empty.
	--- @return boolean # Whether the queue is empty
	function queue:isEmpty()
		return #source == 0
	end

    --- Checks if the queue contains a value.
    --- @param value any
    --- @return boolean # Whether the queue contains the value
	function queue:contains(value)
		for _, v in pairs(source) do
			if (v == value) then
				return true
			end
		end

		return false
	end

    --- Gets all the values in the queue.
    --- @return table
	function queue:getAll()
		return source
	end

	return queue
end

--- Creates a circular buffer from a table which provides push and pop operations
--- and keeps a fixed size.
--- A lookup table is kept to quickly check if a value is in the buffer.
--- @param source table
--- @param size number
--- @param keyFunction function
--- @return CircularBuffer # The circular buffer
function table.CircularBufferWithLookup(source, size, keyFunction)
	--- @class CircularBuffer<T>
	--- @generic T : table
    local buffer = {}

	-- The lookup table to quickly get the index of a value
    local lookup = {}

	-- Tracks the position for the next insertion
	local currentIndex = 1

	function buffer:push(value)
		local key = keyFunction(value)

		-- Insert (or overwrite) the value
		source[currentIndex] = value

		-- If the value already exists, this causes it to only find the most recent index:
		lookup[key] = currentIndex

		-- Move to the next position
		currentIndex = currentIndex + 1

		-- If we reached the end, loop back to the beginning
        if (currentIndex > size) then
            currentIndex = 1
        end
	end

    function buffer:size()
        return #source
    end

    function buffer:isEmpty()
        return #source == 0
    end

	function buffer:find(value)
        local index = lookup[keyFunction(value)]

		return index and source[index] or nil
	end

	function buffer:contains(value)
		return lookup[keyFunction(value)] ~= nil
	end

	function buffer:items()
		return source
	end

	return buffer
end

--- Maps the values of a table to a new table.
--- @param source table
--- @param callback function
--- @return table # The mapped table
function table.Map(source, callback)
	local mapped = {}

	for key, value in pairs(source) do
        local newValue, newKey = callback(value, key)

		if (newKey) then
			mapped[newKey] = newValue
		else
			mapped[key] = newValue
		end
	end

	return mapped
end
