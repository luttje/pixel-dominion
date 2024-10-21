--- @class Player
--- @field inputBlocked boolean
--- @field world World
--- @field faction Faction
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

--- Sets the player world
--- @param world World
function Player:setWorld(world)
	self.world = world
end

--- Gets the player world
--- @return World
function Player:getWorld()
	return self.world
end

--- Sets the player faction
--- @param faction Faction
function Player:setFaction(faction)
    self.faction = faction
end

--- Gets the player faction
--- @return Faction
function Player:getFaction()
	return self.faction
end

return Player
