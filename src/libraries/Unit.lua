require('libraries.Interactable')

--- Represents a unit in the game
--- @class Unit : Interactable
--- @field unitType UnitTypeRegistry.UnitRegistration
--- @field faction Faction
--- @field targetX number # The x position the unit is moving towards
--- @field targetY number # The y position the unit is moving towards
--- @field formation table # The formation the unit is in
--- @field health number # The health of the unit
--- @field currentAction table # The current action the unit is performing
--- @field resourceInventory ResourceInventory
local Unit = DeclareClassWithBase('Unit', Interactable)

--- Initializes the unit
--- @param config table
function Unit:initialize(config)
    config = config or {}

	self:setCurrentAction('idle', nil)

    self.resourceInventory = ResourceInventory({
        maxResources = GameConfig.unitSupplyCapacity,
    })

    table.Merge(self, config)

    self.moveTimer = 0
    self.nextX = self.x
    self.nextY = self.y

	self:reachedTarget()
end

--- Sets the current action
--- @param animation string
--- @param targetInteractable Interactable|nil
function Unit:setCurrentAction(animation, targetInteractable)
    self.currentAction = self.currentAction or {}
    self.currentAction.animation = animation
    self.currentAction.targetInteractable = targetInteractable
end

--- Gets the current action interactable
--- @return Interactable|nil
function Unit:getCurrentActionInteractable()
    return self.currentAction.targetInteractable
end

--- Gets the current action animation
--- @return string
function Unit:getCurrentActionAnimation()
	return self.currentAction.animation
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

--- Gets the resource inventory
--- @return ResourceInventory
function Unit:getResourceInventory()
    return self.resourceInventory
end

--- Draws the unit
function Unit:draw()
    self.unitType:draw(self, self:getCurrentActionAnimation())
end

--- Draws the unit hud icon
--- @param x number
--- @param y number
--- @param width number
--- @param height number
function Unit:drawHudIcon(x, y, width, height)
	self.unitType:drawHudIcon(self, x, y, width, height)
end

--- Called after the unit is drawn on screen
--- @param x number
--- @param y number
--- @param width number
--- @param height number
--- @param cameraScale number
function Unit:postDrawOnScreen(x, y, width, height, cameraScale)
	-- Apply the draw offset to x and y
	local bounceX, bounceY = self:getDrawOffset()
	x = x + bounceX * cameraScale
	y = y + bounceY * cameraScale

	if (self.unitType.postDrawOnScreen) then
		self.unitType:postDrawOnScreen(self, x, y, width, height)
	end

	-- Show how much they carrying as little green rectangles stacking up
	local inventory = self:getResourceInventory()
	local maxResources = inventory:getMaxResources()
	local resources = inventory:getCurrentResources()
	local blockSpacing = 1
	local blockSize = 3
	local blocksPerRow = 5
	local columns = math.ceil(resources / blocksPerRow)
	local blockX = x
	local blockY = y + height - blockSize

	for column = 1, columns do
		local blocksInThisColumn = math.min(blocksPerRow, resources - (column-1) * blocksPerRow)

		for block = 1, blocksInThisColumn do
			-- Adding half so its always crips when stationary.
			-- TODO: Find out why this is needed
			local resourceX = (blockX + (column - 1) * (blockSize + blockSpacing) + 0.5)
			local resourceY = (blockY - (block - 1) * (blockSize + blockSpacing) + 0.5)

			if (not maxResources or resources < maxResources) then
				love.graphics.setColor(0, 1, 0, 1)
			else
				-- TODO: This is red to mark that the inventory is full. That may be confusing with health though, so find a better way to show this.
				love.graphics.setColor(1, 0, 0, 1)
			end

			love.graphics.rectangle('fill', resourceX, resourceY, blockSize, blockSize)

			love.graphics.setColor(0, 0, 0, 1)
			love.graphics.rectangle('line', resourceX, resourceY, blockSize, blockSize)
		end
	end
end

--- Updates the unit
--- @param deltaTime number
function Unit:update(deltaTime)
    -- If we have a target interactable, interact with it if we are at the same position
    local targetInteractable = self:getCurrentActionInteractable()

    if (targetInteractable and not self:isMoving() and targetInteractable:getDistanceTo(self.x, self.y) < 2) then
		targetInteractable:updateInteract(deltaTime, self)
	end

    if (not self:isMoving()) then
        return
    end

	assert(CurrentWorld, 'World is required.')

    self.moveTimer = self.moveTimer + deltaTime

    if (self.moveTimer < GameConfig.unitMoveTimeInSeconds) then
        return
    end

	-- Time to move to the next tile
	self.moveTimer = self.moveTimer - GameConfig.unitMoveTimeInSeconds
    self.x, self.y = self.nextX, self.nextY

	-- Update next position
	if (self.x ~= self.targetX or self.y ~= self.targetY) then
        local pathPoints = self:findPathTo(self.targetX, self.targetY)

		if (pathPoints and #pathPoints > 1) then
            self.maxSteps = self.maxSteps - 1

            -- We see if pathfinding keeps failing in between similar positions and stop.
            if (self.maxSteps <= 0) then
                self:reachedTarget()
				return
            end

			self.nextX, self.nextY = pathPoints[2].x, pathPoints[2].y
		end
    else
		self:reachedTarget()
	end
end

--- Called when the unit reaches its target
function Unit:reachedTarget()
    self.targetX = nil
    self.targetY = nil

	-- Check if the next position is occupied
	if (self:isPositionOccupied(self.nextX, self.nextY)) then
		-- Check if our current position is occupied, if so find a new empty spot to stand
		self.nextX, self.nextY = self:getFreeTileNearby(self:getFaction():getUnits(), self.nextX, self.nextY)

        if (self:isMoving()) then
			if (self.maxSteps) then
            	self.maxSteps = self.maxSteps - 1
			end
        else
			self:commandTo(self.nextX, self.nextY, targetInteractable, self.formation)
		end
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

        -- Add bouncing effect with our formation index as a bit of an offset so units never exactly overlap
        bounceY = bounceY + math.sin(love.timer.getTime() * 10 + ((self.formation and self.formation.index or 1) * 2)) * -1
	end

	return bounceX, bounceY
end

--- Checks if the unit is moving
--- @return boolean
function Unit:isMoving()
    if (not self.targetX or not self.targetY) then
        return false
    end

    return self.x ~= self.targetX or self.y ~= self.targetY
end

--- Checks if the given position is occupied by another unit
--- @param x number
--- @param y number
--- @return boolean
function Unit:isPositionOccupied(x, y)
    for _, unit in ipairs(self:getFaction():getUnits()) do
        if (unit ~= self and unit.x == x and unit.y == y and not unit:isMoving()) then
            return true
        end
    end

    return false
end

--- Calculates the position in a circle formation
--- @param centerX number The x-coordinate of the formation center
--- @param centerY number The y-coordinate of the formation center
--- @param radius number The radius of the circle
--- @param formationIndex number The index of this unit in the formation
--- @param totalUnits number The total number of units in the formation
--- @return number, number The x and y coordinates for this unit in the formation
function Unit:calculateCircleFormationPosition(centerX, centerY, radius, formationIndex, totalUnits)
    local angle = (formationIndex / totalUnits) * (2 * math.pi)
    local x = centerX + radius * math.cos(angle)
    local y = centerY + radius * math.sin(angle)
    return math.floor(x + 0.5), math.floor(y + 0.5)  -- Round to nearest tile
end

--- Calculates the position in a square formation
--- @param centerX number The x-coordinate of the formation center
--- @param centerY number The y-coordinate of the formation center
--- @param size number The size of one side of the square
--- @param formationIndex number The index of this unit in the formation
--- @return number, number The x and y coordinates for this unit in the formation
function Unit:calculateSquareFormationPosition(centerX, centerY, size, formationIndex)
    local unitsPerSide = math.ceil(math.sqrt(formationIndex + 1))
    local x = (formationIndex % unitsPerSide) - math.floor(unitsPerSide / 2)
    local y = math.floor(formationIndex / unitsPerSide) - math.floor(unitsPerSide / 2)
    return math.floor(centerX + x + 0.5), math.floor(centerY + y + 0.5)  -- Round to nearest tile
end

--- Finds a path to or near the target position
function Unit:findPathTo(targetX, targetY)
    assert(CurrentWorld, 'World is required.')

	local pathPoints = CurrentWorld:findPath(self.x, self.y, targetX, targetY)

    if (not pathPoints) then
		-- Look further and further away until we find a free tile is found around the target.
		for range = 1, math.huge do
			for _, offset in ipairs(GameConfig.unitPathingOffsets) do
				local offsetX = targetX + (offset.x * range)
				local offsetY = targetY + (offset.y * range)

                pathPoints = CurrentWorld:findPath(self.x, self.y, offsetX, offsetY)

				if (pathPoints) then
					targetX = offsetX
					targetY = offsetY
					break
				end
			end

            if (pathPoints or range > 100) then
				-- Give up after 100 tries
				break
			end
		end
	end

	return pathPoints, targetX, targetY
end

--- Handles a command to target the given position
--- @param targetX number
--- @param targetY number
--- @param interactable Interactable
--- @param formation table
--- @return boolean
function Unit:commandTo(targetX, targetY, interactable, formation)
    -- If it's the same position, do nothing
    if (self.x == targetX and self.y == targetY) then
        return false
    end

    assert(CurrentWorld, 'World is required.')

	local pathPoints
    pathPoints, targetX, targetY = self:findPathTo(targetX, targetY)

    -- TODO: play a sound or something on fail/succeed walking

    if (not pathPoints or #pathPoints == 1) then
        self.targetX = nil
		self.targetY = nil
		self.formation = nil
        return false
    end

	self.targetX = targetX
	self.targetY = targetY
	self.formation = formation

	if (#pathPoints > 1) then
		self:setCurrentAction('idle', interactable)
	end

	if (not interactable) then
		self:setCurrentAction('idle', nil)
	end

    -- for _, point in ipairs(pathPoints) do
    --     print(('Step: %d - x: %d - y: %d'):format(_, point.x, point.y))
    -- end

    -- Only update the target if we're not currently moving
    if (self.x == self.nextX and self.y == self.nextY) then
        self.moveTimer = 0 -- Reset move timer when starting a new move
    end

    -- The next point in the path becomes our immediate target
    self.nextX = pathPoints[2].x
    self.nextY = pathPoints[2].y
	self.maxSteps = #pathPoints

	return true
end

return Unit
