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
--- @field isSelected boolean # Whether the unit is selected
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

--- Returns the draw offset of the unit. We will bounce when moving or while selected
--- @return number, number
function Unit:getDrawOffset()
	local bounceX, bounceY = 0, 0

	if (self:isMoving()) then
		bounceY = math.sin(love.timer.getTime() * 10) * -1
	end

	if (self.isSelected) then
		-- Rotate in a circle
		bounceX = math.sin(love.timer.getTime() * 10) * 1
		bounceY = math.cos(love.timer.getTime() * 10) * 1
	end

	return bounceX, bounceY
end

--- Checks if the unit is moving
--- @return boolean
function Unit:isMoving()
	return self.x ~= self.targetX or self.y ~= self.targetY
end

--- Checks if the unit is in the given position
--- @param x number
--- @param y number
--- @return boolean
function Unit:isInPosition(x, y)
	return self.x == x and self.y == y
end

--- Selects the unit
--- @param selected boolean
function Unit:setSelected(selected)
	self.isSelected = selected
end

return Unit
