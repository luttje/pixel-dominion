--- @class Player
local Player = DeclareClass('Player')

function Player:initialize(config)
	config = config or {}

	self.inputBlocked = false

	table.Merge(self, config)
end


--- Returns if the player is blocked from clicking buttons
--- @return boolean
function Player:isInputBlocked()
	return self.inputBlocked
end

--- Blocks the player from clicking buttons
--- @param block boolean
function Player:setInputBlocked(block)
	self.inputBlocked = block
end

return Player
