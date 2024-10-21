--- Represents a world that contains factions
--- @class World
--- @field mapPath string # The path to the map file
--- @field factions Faction[] # The factions in the world
local World = DeclareClass('World')

--- Initializes the world
--- @param config table
function World:initialize(config)
	config = config or {}

	assert(config.mapPath, 'Map path is required.')

    self.factions = {}

	table.Merge(self, config)
end

--- Loads the world map
function World:loadMap()
	SimpleTiled.loadMap(self.mapPath)

    SimpleTiled.registerLayerCallback('Dynamic_Units', 'draw', function()
		for _, faction in ipairs(self.factions) do
			for _, unit in ipairs(faction:getUnits()) do
				unit:draw()
			end
		end
	end)

	SimpleTiled.registerLayerCallback('Dynamic_Units', 'update', function(deltaTime)
		for _, faction in ipairs(self.factions) do
			for _, unit in ipairs(faction:getUnits()) do
				unit:update(deltaTime)
			end
		end
	end)
end

--- Updates the world
--- @param deltaTime number # The time since the last update
function World:update(deltaTime)
	SimpleTiled.update(deltaTime)
end

--- Draws the world
function World:draw(translateX, translateY, scaleX, scaleY)
	SimpleTiled.draw(translateX, translateY, scaleX, scaleY)
end

--- Gets the unit or structure under the given world position
--- @param x number
--- @param y number
--- @return Unit|Structure|nil
function World:getEntityUnderPosition(x, y)
	for _, faction in ipairs(self.factions) do
		for _, unit in ipairs(faction:getUnits()) do
			if (unit:isInPosition(x, y)) then
				return unit
			end
		end
	end

	-- TODO:
    -- for _, faction in ipairs(self.factions) do
	-- 	for _, structure in ipairs(faction:getStructures()) do
	-- 		if (structure:isInPosition(x, y)) then
	-- 			return structure
	-- 		end
	-- 	end
	-- end

	return nil
end

--- Adds a faction to the world
--- @param faction Faction
function World:addFaction(faction)
	table.insert(self.factions, faction)
end

return World
