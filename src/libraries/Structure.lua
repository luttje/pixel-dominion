local Interactable = require('libraries.Interactable')

--- Represents a structure value in the game
--- @class Structure : Interactable
---
--- @field structureType StructureTypeRegistry.StructureRegistration
--- @field supply number
---
--- @field unitGenerationQueue Queue<UnitTypeRegistry.UnitRegistration>
local Structure = DeclareClassWithBase('Structure', Interactable)

--- Initializes the structure
--- @param config table
function Structure:initialize(config)
    config = config or {}

	self.sightRange = 12

    table.Merge(self, config)

	self.unitGenerationQueue = table.Queue({})
end

--- Called when the structure spawns
--- @param builders? Unit[]
function Structure:onSpawn(builders)
    if (builders and self.structureType.dropOffForResources) then
        local resourceTypes = table.Stack(table.Keys(self.structureType.dropOffForResources))
		local buildersToAssign = #builders
		local buildersPerResource = math.ceil(buildersToAssign / resourceTypes:size())
		local buildersAssigned = 0

		while (not resourceTypes:isEmpty()) do
			local resourceTypeId = resourceTypes:pop()
			local world = self:getWorld()
			local nearestResourceInstance = world:findNearestResourceInstanceForFaction(
				faction,
				ResourceTypeRegistry:getResourceType(resourceTypeId),
				self.x,
				self.y,
				function(resource)
					local resourceFaction = resource:getFaction()

					if (faction and resourceFaction and resourceFaction ~= faction) then
						return false
					end

					return true
				end
			)

            if (not nearestResourceInstance) then
                break
            end

			-- Have the builders start harvesting the resource
			for i = 1, buildersPerResource do
				local builder = builders[buildersAssigned + i]

				if (builder) then
					builder:commandTo(nearestResourceInstance.x, nearestResourceInstance.y, nearestResourceInstance)
				end

				buildersAssigned = buildersAssigned + 1

				if (buildersAssigned >= buildersToAssign) then
					break
				end
			end

			if (buildersAssigned >= buildersToAssign) then
				break
			end
		end
    end

	if (self.structureType.onSpawn) then
		self.structureType:onSpawn(self, builders)
	end
end

--- Gets the type of structure
--- @return StructureTypeRegistry.StructureRegistration
function Structure:getStructureType()
	return self.structureType
end

--- Draws the interactable on the hud
--- @param x number
--- @param y number
--- @param width number
--- @param height number
function Structure:drawHudIcon(x, y, width, height)
	self.structureType:drawHudIcon(self, x, y, width, height)
end

--- Called after the structure is drawn on screen
--- @param x number
--- @param y number
--- @param width number
--- @param height number
--- @param cameraScale number
function Structure:postDrawOnScreen(x, y, width, height, cameraScale)
    if (self.isRemoved) then
        return
    end

    if (not self:getWorld():isInteractableDiscoveredForFaction(CurrentPlayer:getFaction(), self)) then
        return
    end

	local minX, minY, maxX, maxY = self:getScreenBounds(x, y, cameraScale)
	local centerX = minX + (maxX - minX) * .5
    local centerY = minY + (maxY - minY) * .5

	for i, unitTypeId in ipairs(self.unitGenerationQueue:getAll()) do
		local unitGenerationInfo = self.structureType:getUnitGenerationInfo(unitTypeId)

		if (unitGenerationInfo) then
			local radius, progress

			if (i == 1) then
				radius = (maxX - minX) * .2
				progress = (self.nextUnitGeneratedAt - love.timer.getTime()) / unitGenerationInfo.generationTimeInSeconds()
			else
				radius = (maxX - minX) * .1
				progress = 1
			end

            self:drawUnitProgress(unitGenerationInfo, centerX, centerY, radius, progress)

			centerX = centerX + radius + Sizes.padding(2)
		end
	end

    self:getBase():postDrawOnScreen(x, y, width, height, cameraScale)

	if (self.structureType.postDrawOnScreen) then
		self.structureType:postDrawOnScreen(self, minX, minY, maxX, maxY)
	end
end

--- Returns the draw offset of the structure. We use the bounds to ensure the selection marker is drawn above the center
--- of all tiles instead of the bottom left corner of the structure
--- @return number, number
function Structure:getDrawOffset()
	-- Go through all tiles and return half the width and height as the offset
	local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge

	for _, tile in ipairs(self.tiles) do
		minX = math.min(minX, tile.x)
		minY = math.min(minY, tile.y)
		maxX = math.max(maxX, tile.x)
		maxY = math.max(maxY, tile.y)
	end

	-- TODO: This probably won't work for all structures, especially those that don't have the bottom left corner as the origin
	return (maxX - minX) * .5 * GameConfig.tileSize, (maxY - minY) * -1 * GameConfig.tileSize
end

--- Gets the bounds of the structure on screen
--- @param screenX number
--- @param screenY number
--- @param cameraScale number
--- @return number, number, number, number
function Structure:getScreenBounds(screenX, screenY, cameraScale)
	local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge

	for _, tile in ipairs(self.tiles) do
		local tileX = screenX + tile.offsetX * GameConfig.tileSize * cameraScale
		local tileY = screenY + tile.offsetY * GameConfig.tileSize * cameraScale

		minX = math.min(minX, tileX)
		minY = math.min(minY, tileY)
		maxX = math.max(maxX, tileX + GameConfig.tileSize * cameraScale)
		maxY = math.max(maxY, tileY + GameConfig.tileSize * cameraScale)
	end

	return minX, minY, maxX, maxY
end

--- Draws the border of the structure on screen
--- @param minX number
--- @param minY number
--- @param maxX number
--- @param maxY number
function Structure:drawScreenBorder(minX, minY, maxX, maxY)
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle('line', minX, minY, maxX - minX, maxY - minY)
end

--- Called every tick
--- @param deltaTime number
function Structure:update(deltaTime)
    if (self.isRemoved) then
        return
    end

    if (not self.nextUpdateAt) then
        self.nextUpdateAt = love.timer.getTime() + GameConfig.structureUpdateTimeInSeconds()
    end

    if (self.nextUpdateAt > love.timer.getTime()) then
        return
    end

	self.nextUpdateAt = nil

	if (self.structureType.unitGenerationInfo) then
		self:handleUnitGenerationTimedUpdate()
	end

	if (self.structureType.onTimedUpdate) then
		self.structureType:onTimedUpdate(self)
	end
end

--- Gets whether the structure can generate a unit
--- @param unitGenerationInfo table
--- @return boolean
function Structure:canGenerateUnit(unitGenerationInfo)
    local factionInventory = self:getFaction():getResourceInventory()

	for resourceTypeId, amount in pairs(unitGenerationInfo.costs) do
		if (not factionInventory:has(resourceTypeId, amount)) then
			return false
		end
	end

	return true
end

--- @return table
function Structure:getActions()
	local actions = {}

	if (self.structureType.unitGenerationInfo) then
		for _, unitGenerationInfo in ipairs(self.structureType.unitGenerationInfo) do
            local action = {}
			action.id = unitGenerationInfo.id
			action.text = unitGenerationInfo.text
            action.icon = unitGenerationInfo.icon
			action.costs = unitGenerationInfo.costs

			action.isEnabled = function(actionButton)
				return self:canGenerateUnit(unitGenerationInfo)
			end

			action.onRun = function(actionButton, selectionOverlay)
				self:enqueueUnitGeneration(unitGenerationInfo)
			end

			table.insert(actions, action)
		end
	end

	return actions
end

--- Enqueues a unit generation
--- @param unitGenerationInfo UnitGenerationInfo
--- @return boolean
function Structure:enqueueUnitGeneration(unitGenerationInfo)
    if (not self:canGenerateUnit(unitGenerationInfo)) then
        return false
    end

    local factionInventory = self:getFaction():getResourceInventory()

    for resourceTypeId, amount in pairs(unitGenerationInfo.costs) do
        factionInventory:remove(resourceTypeId, amount)
    end

    self.unitGenerationQueue:enqueue(unitGenerationInfo.unitTypeId)

	if (not self.nextUnitGeneratedAt) then
		self.nextUnitGeneratedAt = love.timer.getTime() + unitGenerationInfo.generationTimeInSeconds()
	end

    return true
end

--- Checks if the given unit type id is in the unit generation queue
--- @param unitTypeId string
--- @return boolean
function Structure:isUnitInGenerationQueue(unitTypeId)
	return self.unitGenerationQueue:contains(unitTypeId)
end

--- Cancels the unit generation
--- @param unitTypeId string
function Structure:cancelUnitGeneration(unitTypeId)
    if (not self.unitGenerationQueue:dequeue(unitTypeId)) then
        return
    end

    local factionInventory = self:getFaction():getResourceInventory()
    local unitGenerationInfo = self.structureType:getUnitGenerationInfo(unitTypeId)

    for resourceTypeId, amount in pairs(unitGenerationInfo.costs) do
        factionInventory:add(resourceTypeId, amount)
    end
end

--- Gets the current unit generation info
--- @return table|nil
function Structure:getCurrentUnitGenerationInfo()
    local unitTypeId = self.unitGenerationQueue:peek()

	if (not unitTypeId) then
		return
	end

    local currentUnitGenerationInfo = self.structureType:getUnitGenerationInfo(unitTypeId)

	assert(currentUnitGenerationInfo, 'Unit generation info not found for unit type id: ' .. unitTypeId)

	return currentUnitGenerationInfo
end

--- Handles the generation of units
--- Called at the same rate as onTimedUpdate
function Structure:handleUnitGenerationTimedUpdate()
    local currentUnitGenerationInfo = self:getCurrentUnitGenerationInfo()

	if (not currentUnitGenerationInfo) then
		return
	end

	local faction = self:getFaction()
    local units = faction:getUnits()
    local housing = faction:getResourceInventory():getValue('housing')

	if (#units >= housing) then
		print('Cannot generate unit.', #units, housing)

		return
	end

    if (self.nextUnitGeneratedAt > love.timer.getTime()) then
        return
    end

	self.nextUnitGeneratedAt = love.timer.getTime() + currentUnitGenerationInfo.generationTimeInSeconds()
    self.unitGenerationQueue:dequeue() -- Remove the unit from the queue, it has been generated
    self:generateUnit(currentUnitGenerationInfo.unitTypeId)
end

--- Generates a unit
--- @param unitTypeOrId UnitTypeRegistry.UnitRegistration|string
function Structure:generateUnit(unitTypeOrId)
	local faction = self:getFaction()
    local units = faction:getUnits()
    local housing = faction:getResourceInventory():getValue('housing')

	local unitType = type(unitTypeOrId) == 'string' and UnitTypeRegistry:getUnitType(unitTypeOrId) or unitTypeOrId

	if (#units >= housing) then
		return
	end

    local x, y = self:getFreeTileNearby(nil, nil, nil, 10)

    if (not x or not y) then
        print('No free tile found around the structure.')
        return
    end

	faction:spawnUnit(
        unitType,
        x, y
	)
end

--- Draws how much progress has been made generating a unit
--- @param unitGenerationInfo table
--- @param x number
--- @param y number
--- @param radius number
--- @param progress number
function Structure:drawUnitProgress(unitGenerationInfo, x, y, radius, progress)
	love.graphics.drawProgressCircle(
		x,
		y,
        radius,
		progress)

	-- Draw the villager icon over the progress circle
	local padding = Sizes.padding()
	local iconWidth = radius * 2 - padding * 2
	local iconHeight = radius * 2 - padding * 2
	local unitType = UnitTypeRegistry:getUnitType(unitGenerationInfo.unitTypeId)

	love.graphics.setColor(1, 1, 1)
	unitType:drawHudIcon(nil, x - radius + padding, y - radius + padding, iconWidth, iconHeight)
end

--- Whether the structure can take damage from the interactor
--- @param interactor Interactable
--- @return boolean
function Structure:canTakeDamageFrom(interactor)
	return interactor:getFaction() ~= self:getFaction()
end

--- When an interactable is interacted with
--- @param deltaTime number
--- @param interactor Interactable
--- @return boolean # Whether the interactable was interacted with
function Structure:updateInteract(deltaTime, interactor)
    if (not self:getBase():updateInteract(deltaTime, interactor)) then
        return false
    end

    if (self.isRemoved) then
        return false
    end

	-- Have compatible structures take any resources from the unit and place them in the faction inventory
    if (interactor:getFaction() == self:getFaction() and self.structureType.dropOffForResources and interactor) then
		local inventory = interactor:getResourceInventory()

		if (inventory:getCurrentResources() > 0) then
			local faction = self:getFaction()
			local factionInventory = faction:getResourceInventory()
			local lastResourceInstance = interactor:getLastResourceInstance()
			local world = faction:getWorld()

			assert(lastResourceInstance, 'No last resource instance found.')

			for resourceTypeId, resourceValue in pairs(inventory:getAll()) do
				local value = resourceValue.value

				-- Remove only the resources that the structure can drop off
				if (self.structureType.dropOffForResources[resourceTypeId]) then
					local dropOffMultiplier = tonumber(self.structureType.dropOffForResources[resourceTypeId])

					if (dropOffMultiplier) then
						value = value * dropOffMultiplier
					end

					factionInventory:add(resourceTypeId, value)
					inventory:remove(resourceTypeId, value)
				end
			end

			-- First go back to the last resource we came from if it has any supply left
			if (lastResourceInstance:getSupply() > 0 and not lastResourceInstance.isRemoved) then
				interactor:commandTo(lastResourceInstance.x, lastResourceInstance.y, lastResourceInstance)

				return true
			end

			-- Find the nearest resource instance of the same type
			local nearestResourceInstance = world:findNearestResourceInstanceForFaction(
				faction,
				lastResourceInstance:getResourceType(),
				self.x,
				self.y,
				function(resource)
					local resourceFaction = resource:getFaction()

					if (faction and resourceFaction and resourceFaction ~= faction) then
						return false
					end

					return true
				end
			)

			if (nearestResourceInstance) then
				interactor:commandTo(nearestResourceInstance.x, nearestResourceInstance.y, nearestResourceInstance)

				return true
			end
		end
	end

	if (self.structureType.updateInteract) then
		local interacted = self.structureType:updateInteract(self, deltaTime, interactor)

        if (not interacted) then
			interactor:stop()
		end
	end

	return true
end

--- Removes the structure from the world
function Structure:remove()
    if (self.isRemoved) then
        return
    end

	self:getBase():remove()

	if (self.structureType.onRemove) then
		self.structureType:onRemove(self)
	end

	self:getFaction():removeStructure(self)
	self:setSelected(false)

    self.events:trigger('structureRemoved')
end

return Structure
