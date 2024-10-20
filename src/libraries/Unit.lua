--- Represents a unit in the game, controller by a controller, which can be a player or an AI
--- @class Unit
--- @field controller UnitController
--- @field unitType UnitTypeRegistry.UnitRegistration
--- @field x number # The x position of the unit
--- @field y number # The y position of the unit
--- @field targetX number # The x position the unit is moving towards
--- @field targetY number # The y position the unit is moving towards
--- @field health number # The health of the unit
--- @field currentAction string # The current action the unit is performing
local Unit = DeclareClass('Unit')

--- Initializes the unit
--- @param config table
function Unit:initialize(config)
	config = config or {}

	table.Merge(self, config)
end

--- Gets who/what is controlling the unit
--- @return UnitController
function Unit:getController()
	return self.controller
end

--- Gets the type of unit
--- @return UnitTypeRegistry.UnitRegistration
function Unit:getUnitType()
	return self.unitType
end

--- Draws the unit
function Unit:draw()
	self.unitType:draw(self, self.currentAction)
end

--- Updates the unit
--- @param deltaTime number
function Unit:update(deltaTime)
	-- TODO: Implement
end

return Unit
