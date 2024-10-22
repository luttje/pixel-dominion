local cooldowns = {}

--- These are common cooldown keys that can be used.
--- @enum
COMMON_COOLDOWNS = {
    POINTER_INPUT = 'POINTER_INPUT',

    WORLD_INPUT = 'WORLD_INPUT',
	WORLD_INPUT_RELEASED = 'WORLD_INPUT_RELEASED',

	WORLD_COMMAND = 'WORLD_COMMAND',
}

--- Cooldown function so we can delay actions with a certain amount of time.
--- @param key string The key to identify the cooldown.
--- @param cooldownTime number The time to wait before the cooldown is over.
--- @param callback function The function to call if the cooldown is over.
function TryCallIfNotOnCooldown(key, cooldownTime, callback)
    if (not cooldowns[key]) then
		cooldowns[key] = os.time() + cooldownTime
        callback()
    elseif (os.time() >= cooldowns[key]) then
		cooldowns[key] = os.time() + cooldownTime
        callback()
	else
		-- Do nothing if the cooldown is still active
	end
end
