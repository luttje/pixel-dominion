--- Represents a world that contains units and structures
--- @class World
--- @field mapPath string # The path to the map file
--- @field staticCollisionMap table # Collision map for static map objects/tiles
--- @field units table<number, Unit> # The units in the world
--- @field structures table<number, Structure> # The structures in the world
local World = DeclareClass('World')

--- Initializes the world
--- @param config table
function World:initialize(config)
	config = config or {}

	assert(config.mapPath, 'Map path is required.')

	self.units = {}
	self.structures = {}

	table.Merge(self, config)
end

--- Loads the world map
function World:loadMap()
	SimpleTiled.loadMap(self.mapPath)

	SimpleTiled.registerLayerCallback('Dynamic_Units', 'draw', function()
		for _, unit in ipairs(self.units) do
			unit:draw()
		end
	end)

	SimpleTiled.registerLayerCallback('Dynamic_Units', 'update', function(deltaTime)
		for _, unit in ipairs(self.units) do
			unit:update(deltaTime)
		end
	end)

	self.staticCollisionMap = SimpleTiled.getCollisionMap()
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

--- Spawns a unit of the given type at the given position
--- @param unitType UnitTypeRegistry.UnitRegistration
--- @param x number
--- @param y number
--- @return Unit
function World:spawnUnit(unitType, x, y)
	local unit = Unit({
		controller = CurrentPlayer,
		unitType = unitType,
		x = x,
		y = y,
		targetX = x,
		targetY = y,
		health = 100,
		currentAction = 'idle'
	})

	table.insert(self.units, unit)

	return unit
end

--- Gets the unit or structure under the given world position
--- @param x number
--- @param y number
--- @return Unit|Structure|nil
function World:getEntityUnderPosition(x, y)
	for _, unit in ipairs(self.units) do
		if (unit:isInPosition(x, y)) then
			return unit
		end
	end

	for _, structure in ipairs(self.structures) do
		if (structure:isInPosition(x, y)) then
			return structure
		end
	end

	return nil
end

return World
