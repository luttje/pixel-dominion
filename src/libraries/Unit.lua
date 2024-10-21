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
	self.unitType:drawHudIcon(x, y, width, height)
end

--- Updates the unit
--- @param deltaTime number
function Unit:update(deltaTime)
    -- If we have a target interactable, interact with it if we are at the same position
    local targetInteractable = self:getCurrentActionInteractable()

	if (targetInteractable and targetInteractable:isInPosition(self.x, self.y)) then
		targetInteractable:updateInteract(deltaTime, self)
	end

	-- Check if the next position is occupied
	if (self:isPositionOccupied(self.nextX, self.nextY)) then
		-- Check if our current position is occupied, if so find a new empty spot to stand
		self.nextX, self.nextY = self:getFreeTileNearby(self:getFaction():getUnits(), self.nextX, self.nextY)

		if (self:isMoving()) then
            self.maxSteps = self.maxSteps - 1
        else
			self:commandTo(self.nextX, self.nextY, targetInteractable, self.formation)
		end
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
	-- self.x = self.nextX
	-- self.y = self.nextY

	-- -- Find the next tile in the path
    -- local pathPoints = CurrentWorld:findPath(self.x, self.y, self.targetX, self.targetY)

	-- if (pathPoints) then
	-- 	if (#pathPoints > 1) then
	-- 		-- The next point in the path becomes our immediate target
	-- 		self.nextX = pathPoints[2].x
    --         self.nextY = pathPoints[2].y

	-- 		-- TODO: Commented because too glitchy, need to fix
	-- 		-- local formation = self.formation

	-- 		-- if (formation.centerUnit ~= self) then
    --         -- local centerX, centerY = formation.centerUnit.x, formation.centerUnit.y
	-- 		-- 	if (formation.type == 'circle') then
	-- 		-- 		self.nextX, self.nextY = self:calculateCircleFormationPosition(centerX, centerY, 1, formation.index, formation.size)
	-- 		-- 	elseif (formation.type == 'square') then
	-- 		-- 		self.nextX, self.nextY = self:calculateSquareFormationPosition(centerX, centerY, math.ceil(math.sqrt(formation.size)), formation.index)
	-- 		-- 	end
	-- 		-- end
	-- 	else
	-- 		-- We've reached the target
	-- 		self.targetX = nil
	-- 		self.targetY = nil
	-- 		self.nextX = self.x
	-- 		self.nextY = self.y

	-- 		self:reachedTarget()
	-- 	end
	-- end

    self.x, self.y = self.nextX, self.nextY

	-- Update next position
	if (self.x ~= self.targetX or self.y ~= self.targetY) then
        local pathPoints = CurrentWorld:findPath(self.x, self.y, self.targetX, self.targetY)

		if (pathPoints and #pathPoints > 1) then
            self.maxSteps = self.maxSteps - 1

            -- We see if pathfinding keeps failing in between similar positions and stop.
            if (self.maxSteps <= 0) then
                self:reachedTarget()
				return
            end

			self.nextX, self.nextY = pathPoints[2].x, pathPoints[2].y
		else
			self:reachedTarget()
		end
	else
		self:reachedTarget()
	end
end

--- Called when the unit reaches its target
function Unit:reachedTarget()
    self.targetX = nil
	self.targetY = nil
end

--- Returns the draw offset of the unit. We will bounce when moving or while selected
--- @return number, number
function Unit:getDrawOffset()
    local targetInteractable = self:getCurrentActionInteractable()
	local bounceX, bounceY = 0, 0

	if (self:isMoving() and not self:isPositionOccupied(self.nextX, self.nextY)) then
        -- Calculate interpolation factor between the current and next tile
        local factor = self.moveTimer / GameConfig.unitMoveTimeInSeconds

        -- Interpolate between current position and next position
        bounceX = (self.nextX - self.x) * factor * GameConfig.tileSize
        bounceY = (self.nextY - self.y) * factor * GameConfig.tileSize

        -- Add bouncing effect with our formation index as a bit of an offset so units never exactly overlap
        bounceY = bounceY + math.sin(love.timer.getTime() * 10 + ((self.formation and self.formation.index or 1) * 2)) * -1
    elseif (targetInteractable) then
        -- Set us to be at the interactable's position
        bounceX = (targetInteractable.x - self.x) * GameConfig.tileSize
		bounceY = (targetInteractable.y - self.y) * GameConfig.tileSize
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

--- Finds the nearest unoccupied position to the target
--- @param targetX number
--- @param targetY number
--- @return number, number
function Unit:findNearestUnoccupiedPosition(targetX, targetY)
    local checkRadius = 1
    local maxRadius = 5 -- Adjust this value based on your game's needs

    while (checkRadius <= maxRadius) do
        for dy = -checkRadius, checkRadius do
            for dx = -checkRadius, checkRadius do
                local newX, newY = targetX + dx, targetY + dy

                if (not self:isPositionOccupied(newX, newY)) then
                    return newX, newY
                end
            end
        end

        checkRadius = checkRadius + 1
    end

    return targetX, targetY -- Return original target if no free position found
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

--- Handles a command to target the given position
--- @param targetX number
--- @param targetY number
--- @param interactable Interactable
--- @param formation table
--- @return boolean
function Unit:commandTo(targetX, targetY, interactable, formation)
	self.targetX = targetX
	self.targetY = targetY
	self.formation = formation

    -- If it's the same position, do nothing
    if (self.x == targetX and self.y == targetY) then
        return false
    end

    assert(CurrentWorld, 'World is required.')

    local pathPoints = CurrentWorld:findPath(self.x, self.y, targetX, targetY)

    -- TODO: play a sound or something on fail/succeed walking

    if (not pathPoints) then
		-- Find a path somewhere around the interactable
		if (interactable) then
			for _, offset in ipairs(GameConfig.unitPathingOffsets) do
				local offsetX = interactable.x + offset.x
				local offsetY = interactable.y + offset.y

				pathPoints = CurrentWorld:findPath(self.x, self.y, offsetX, offsetY)

                if (pathPoints) then
                    targetX = offsetX
					targetY = offsetY
					break
				end
			end
		end

		if (not pathPoints) then
        	print('No path found!')
        	return false
		end
    end

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
