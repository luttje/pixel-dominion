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

    self.moveTimer = 0
    self.nextX = self.x
    self.nextY = self.y
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
    if (not self:isMoving()) then
        return
    end

    self.moveTimer = self.moveTimer + deltaTime

    if (self.moveTimer < GameConfig.unitMoveTimeInSeconds) then
        return
    end

	-- Time to move to the next tile
	self.moveTimer = self.moveTimer - GameConfig.unitMoveTimeInSeconds
	self.x = self.nextX
	self.y = self.nextY

	-- Find the next tile in the path
    local pathPoints = SimpleTiled.findPath(self.x, self.y, self.targetX, self.targetY)

	if (pathPoints and #pathPoints > 1) then
		-- The next point in the path becomes our immediate target
		self.nextX = pathPoints[2].x
		self.nextY = pathPoints[2].y
	else
		-- We've reached the target or there's no path
		self.nextX = self.targetX
		self.nextY = self.targetY
	end
end

--- Returns the draw offset of the unit. We will bounce when moving or while selected
--- @return number, number
function Unit:getDrawOffset()
	local bounceX, bounceY = 0, 0

	if (self:isMoving()) then
        -- Calculate interpolation factor between the current and next tile
        local factor = self.moveTimer / GameConfig.unitMoveTimeInSeconds

        -- Interpolate between current position and next position
        bounceX = (self.nextX - self.x) * factor * GameConfig.tileSize
        bounceY = (self.nextY - self.y) * factor * GameConfig.tileSize

        -- Add bouncing effect
        bounceY = bounceY + math.sin(love.timer.getTime() * 10) * -1
	elseif (self.isSelected) then
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

--- Handles a command to target the given position
--- @param targetX number
--- @param targetY number
--- @param interactable Interactable # TODO: Always nil for now. Fix that to be an interactable at the target position
--- @return boolean
function Unit:commandTo(targetX, targetY, interactable)
    -- If its the same position, do nothing
    if (self.x == targetX and self.y == targetY) then
        return false
    end

	local pathPoints = SimpleTiled.findPath(self.x, self.y, targetX, targetY)

    -- TODO: play a sound or something on fail/succeed walking

    if (not pathPoints) then
        print('No path found!')
        return false
    end

    -- for _, point in ipairs(pathPoints) do
    --     print(('Step: %d - x: %d - y: %d'):format(_, point.x, point.y))
    -- end

    -- Only update the target if we're not currently moving
    if (self.x == self.nextX and self.y == self.nextY) then
        self.targetX = targetX
        self.targetY = targetY
        self.moveTimer = 0  -- Reset move timer when starting a new move

        -- Set the next immediate target
        if (#pathPoints > 1) then
            self.nextX = pathPoints[2].x
            self.nextY = pathPoints[2].y
        else
            self.nextX = targetX
            self.nextY = targetY
        end
    else
        -- If we're currently moving, just update the final target
        self.targetX = targetX
        self.targetY = targetY
    end

	return true
end

return Unit
