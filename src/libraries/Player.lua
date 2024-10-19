--- @class Player
local Player = DeclareClass('Player')

function Player:initialize(config)
	config = config or {}

    self.currentRegionIndex = 1 -- TODO: Make this 1 again , just for testing
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

function Player:increaseRegionIndex()
    self.currentRegionIndex = self.currentRegionIndex + 1

	return self.currentRegionIndex
end

function Player:getRegionIndex()
	return self.currentRegionIndex
end

return Player
