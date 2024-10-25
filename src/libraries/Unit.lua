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
--- @field lastResourceInstance Resource|nil # The last resource instance the unit interacted with
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

--- Stops the unit from whatever it is doing
function Unit:stop()
	self.targetX = nil
	self.targetY = nil
	self.formation = nil
	self:setCurrentAction('idle', nil)
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

--- Called when the unit spawns
function Unit:onSpawn()
	if (self.unitType.onSpawn) then
		self.unitType:onSpawn(self)
	end
end

--- Draws the unit
function Unit:draw()
	love.graphics.setColor(1, 1, 1)
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
	-- TODO: Doesn't look very good half the time (offset slightly), so commented out for now #12
	-- CurrentWorldMap:drawInWorldSpace(function()
	-- 	love.graphics.setColor(1, 1, 1, 0.25)
	-- 	self.unitType:draw(self, self:getCurrentActionAnimation())
	-- end)

    self:getBase():postDrawOnScreen(x, y, width, height, cameraScale)

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

--- Whether the unit can take damage from the interactor
--- @param interactor Interactable
--- @return boolean
function Unit:canTakeDamageFrom(interactor)
	return interactor:getFaction() ~= self:getFaction()
end

--- Called when this unit destroyed the given interactable
--- @param interactable Interactable
function Unit:onInteractWithDestroyedInteractable(interactable)
	local enemyFaction = interactable:getFaction()

	-- Find a nearby faction interactable to now target
	local nearbyInteractable = CurrentWorld:findNearestInteractable(self.x, self.y, function(otherInteractable)
		return otherInteractable:getFaction() == enemyFaction and not otherInteractable.isRemoved
	end)

	if (nearbyInteractable) then
		print('Found nearby interactable to target next.')
		self:commandTo(nearbyInteractable.x, nearbyInteractable.y, nearbyInteractable, self.formation)
	else
		print('No nearby interactable found to target.')
		self:stop()
	end
end

--- When an interactable is interacted with
--- @param deltaTime number
--- @param interactor Interactable
--- @return boolean # Whether the interactable was interacted with
function Unit:updateInteract(deltaTime, interactor)
    if (not self:getBase():updateInteract(deltaTime, interactor)) then
        return false
    end

	if (self.unitType.updateInteract) then
		local interacted = self.unitType:updateInteract(self, deltaTime, interactor)

        if (not interacted) then
			print('Interact ended.')
			interactor:stop()
		end
	end

	return true
end

--- Updates the unit
--- @param deltaTime number
function Unit:update(deltaTime)
    if (self.isRemoved) then
        return
    end

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
	local unitInTheWay = self:isPositionOccupied(self.nextX, self.nextY)
	if (unitInTheWay) then
		-- If someone is in the way and they are not moving, move them out of the way
        if (not unitInTheWay:isMoving()) then
			if (not unitInTheWay:isInteracting()) then
				local x, y = self:getFreeTileNearby(self:getFaction():getUnits(), self.nextX, self.nextY)

				if (not x or not y) then
					print('No free tile found around the unit in the way.')
					return
				end

				unitInTheWay:commandTo(x, y, nil, self.formation)
			else
                -- Currently units are allowed to stand on top of each other if they are interacting with something.
				-- We compensate for this in the draw offset so they don't overlap visually.
				-- TODO: Have them stand on different tiles when interacting with something.
			end
		else
			assert(false, 'Checking if this actually happens') -- don't think this should happen
			print('Unit in the way, waiting for them to move.')
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
end

--- Returns the draw offset of the unit. We will bounce when moving or while selected
--- @return number, number
function Unit:getDrawOffset()
	local offsetX, offsetY = 0, 0

	if (self:isMoving()) then
        -- Calculate interpolation factor between the current and next tile
        local factor = self.moveTimer / GameConfig.unitMoveTimeInSeconds

        -- Interpolate between current position and next position
        offsetX = (self.nextX - self.x) * factor * GameConfig.tileSize
        offsetY = (self.nextY - self.y) * factor * GameConfig.tileSize

        -- Add bouncing effect with our formation index as a bit of an offset so units never exactly overlap,
        -- ensuring the bounce is within the tile
		offsetY = offsetY + (math.sin(love.timer.getTime() * 10 + (self.formation and self.formation.index or 1)) * GameConfig.tileSize * .25) - (GameConfig.tileSize * .25)
    elseif (self:isInteracting()) then
        offsetY = math.sin(self.id * GameConfig.tileSize)
		offsetX = math.cos(self.id * GameConfig.tileSize)
	end

	return offsetX, offsetY
end

--- Checks if the unit is moving
--- @return boolean
function Unit:isMoving()
    if (not self.targetX or not self.targetY) then
        return false
    end

    return self.x ~= self.targetX or self.y ~= self.targetY
end

--- Checks if the unit is interacting with something
--- @return boolean
function Unit:isInteracting()
	return self:getCurrentActionInteractable() ~= nil
end

--- Sets the last resource instance the unit interacted with
--- @param resource Resource
function Unit:setLastResourceInstance(resource)
    self.lastResourceInstance = resource
end

--- Gets the last resource instance the unit interacted with
--- @return Resource|nil
function Unit:getLastResourceInstance()
	return self.lastResourceInstance
end

--- Checks if the given position is occupied by another unit
--- @param x number
--- @param y number
--- @return boolean|Unit
function Unit:isPositionOccupied(x, y)
    for _, unit in ipairs(self:getFaction():getUnits()) do
        if (unit ~= self and unit.x == x and unit.y == y and not unit:isMoving()) then
            return unit
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
    if (self.isRemoved) then
        return
    end

	-- Commented because farmland has the unit stand on it, but the structure redirects to the resource instance on the same tile.
    -- -- If it's the same position, do nothing
    -- if (self.x == targetX and self.y == targetY) then
    --     return false
    -- end

    assert(CurrentWorld, 'World is required.')

	local pathPoints
    pathPoints, targetX, targetY = self:findPathTo(targetX, targetY)

    -- TODO: play a sound or something on fail/succeed walking

    if (not pathPoints) then
        self.targetX = nil
		self.targetY = nil
		self.formation = nil
        return false
    end

	self.targetX = targetX
	self.targetY = targetY
	self.formation = formation

    -- Only update the target if we're not currently moving
    if (self.x == self.nextX and self.y == self.nextY) then
        self.moveTimer = 0 -- Reset move timer when starting a new move
    end

    if (interactable) then
        self:setCurrentAction('idle', interactable)
	else
		self:setCurrentAction('idle', nil)
	end

    -- for _, point in ipairs(pathPoints) do
    --     print(('Step: %d - x: %d - y: %d'):format(_, point.x, point.y))
    -- end

    -- The next point in the path becomes our immediate target
    self.nextX = pathPoints[1].x
    self.nextY = pathPoints[1].y
    self.maxSteps = #pathPoints

	return true
end

--- Removes the unit from the world
function Unit:remove()
    if (self.isRemoved) then
        return
    end

    self.isRemoved = true

	if (self.unitType.onRemove) then
		self.unitType:onRemove(self)
	end

	self:getFaction():removeUnit(self)

    self.events:trigger('unitRemoved')
end

return Unit
