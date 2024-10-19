--- Clamps a number between two values.
--- @param value number
--- @param min number
--- @param max number
--- @return number
function math.Clamp(value, min, max)
	return math.min(math.max(value, min), max)
end

local oldTransitionValues = {}

--- Transitions a value from one value to another.
--- Uses delta time to calculate the transition.
--- The value has a named key, so the previous value can be stored.
--- @param key string
--- @param target number # The current value to transition to, will be stored for the next transition.
--- @param original number # The original value to transition from if no previous value exists.
--- @param speed number # The speed of the transition.
--- @return number
function math.Transition(key, target, original, speed)
	if (oldTransitionValues[key] == nil) then
        oldTransitionValues[key] = original
	end

    local oldValue = oldTransitionValues[key]

    if (math.AlmostEquals(oldValue, target)) then
		oldTransitionValues[key] = target
        return target
    end

	local delta = speed * math.min(1, love.timer.getDelta()) * (target > oldValue and 1 or -1)

	if (target > oldValue) then
    	oldTransitionValues[key] = math.min(target, oldValue + delta)
	else
		oldTransitionValues[key] = math.max(target, oldValue + delta)
	end

    return oldTransitionValues[key]
end

--- Clears a transition value.
--- @param key string
function math.ClearTransition(key)
	oldTransitionValues[key] = nil
end

--- Checks if floating point numbers are almost equal.
--- @param a number The first number.
--- @param b number The second number.
--- @param epsilon? number The maximum difference between the two numbers.
--- @return boolean
function math.AlmostEquals(a, b, epsilon)
	epsilon = epsilon or 0.00001
	return math.abs(a - b) < epsilon
end

--- Parses a percentage value from a string if it ends with a percentage sign.
--- Returns the value if it is not a percentage.
--- @param value any
--- @param relativeValue any
--- @return number|any
function math.ParsePercentage(value, relativeValue)
	if (type(value) == 'string' and value:sub(-1) == '%') then
		local valueAsNumber = tonumber(value:sub(1, -2))

		assert(valueAsNumber, 'Invalid percentage value: ' .. value)

		return relativeValue * valueAsNumber / 100
	end

	return value
end

--- Parses a value from a string if it ends with a percentage sign to a scale.
--- Returns 1 if it is not a percentage.
--- @param value any
--- @param relativeValue any
--- @return number
function math.ParsePercentageToScale(value, relativeValue)
	return math.ParsePercentage(value, relativeValue) / relativeValue
end

--- Rounds a number to the nearest decimal position.
--- @param value number
--- @param decimalPlaces? number # The number of decimal places to round to, defaults to 0.
--- @return number
function math.Round(value, decimalPlaces)
	decimalPlaces = decimalPlaces or 0
	local mult = 10 ^ decimalPlaces

	return math.floor(value * mult + 0.5) / mult
end
