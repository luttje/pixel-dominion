require('libraries.Interactable')

--- Represents a unit in the game
--- @class Unit : Interactable
--- @field unitType UnitTypeRegistry.UnitRegistration
--- @field faction Faction
--- @field targetX number # The x position the unit is moving towards
--- @field targetY number # The y position the unit is moving towards
--- @field health number # The health of the unit
--- @field currentAction string # The current action the unit is performing
local Unit = DeclareClassWithBase('Unit', Interactable)

--- Initializes the unit
--- @param config table
function Unit:initialize(config)
	config = config or {}

	table.Merge(self, config)
end

--- Gets the type of unit
--- @return UnitTypeRegistry.UnitRegistration
function Unit:getUnitType()
	return self.unitType
end

--- Gets the faction
--- @return Faction
function Unit:getFaction()
	return self.faction
end

--- Draws the unit
function Unit:draw()
    self.unitType:draw(self, self.currentAction)
end

--- Draws the unit hud icon
--- @param x number
--- @param y number
--- @param width number
--- @param height number
function Unit:drawHudIcon(x, y, width, height)
	self.unitType:drawHudIcon(x, y, width, height)
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

return Unit
