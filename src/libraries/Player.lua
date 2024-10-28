--- @class Player
--- @field world World
--- @field faction Faction
local Player = DeclareClass('Player')

function Player:initialize(config)
    assert(config.name, 'Player name not specified')

    config = config or {}

    table.Merge(self, config)
end

--- Gets the player name
--- @return string
function Player:getName()
	return self.name
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
