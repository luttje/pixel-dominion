require('libraries.Interactable')

--- Represents a structure value in the game
--- @class Structure : Interactable
---
--- @field structureType StructureTypeRegistry.StructureRegistration
--- @field faction Faction
--- @field supply number
--- @field tiles table
---
--- @field unitGenerationQueue Queue<UnitTypeRegistry.UnitRegistration>
local Structure = DeclareClassWithBase('Structure', Interactable)

--- Initializes the structure
--- @param config table
function Structure:initialize(config)
    config = config or {}

    table.Merge(self, config)

	self.unitGenerationQueue = table.Queue({})
end

--- Called when the structure spawns
--- @param builders? Unit[]
function Structure:onSpawn(builders)
	if (self.structureType.onSpawn) then
		self.structureType:onSpawn(self, builders)
	end
end

--- Gets the type of structure
--- @return StructureTypeRegistry.StructureRegistration
function Structure:getStructureType()
	return self.structureType
end

--- Gets the faction
--- @return Faction
function Structure:getFaction()
	return self.faction
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

	for i, cost in ipairs(unitGenerationInfo.costs) do
		if (not factionInventory:has(cost.resourceTypeId, cost.value)) then
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
--- @param unitGenerationInfo table
--- @return boolean
function Structure:enqueueUnitGeneration(unitGenerationInfo)
    if (not self:canGenerateUnit(unitGenerationInfo)) then
        return false
    end

    local factionInventory = self:getFaction():getResourceInventory()

    for i, cost in ipairs(unitGenerationInfo.costs) do
        factionInventory:remove(cost.resourceTypeId, cost.value)
    end

    if (self.nextUnitGeneratedAt == nil) then
        self.nextUnitGeneratedAt = love.timer.getTime() + unitGenerationInfo.generationTimeInSeconds()
    end

    self.unitGenerationQueue:enqueue(unitGenerationInfo.unitTypeId)

    return true
end

--- Cancels the unit generation
--- @param unitTypeId string
function Structure:cancelUnitGeneration(unitTypeId)
    if (not self.unitGenerationQueue:dequeue(unitTypeId)) then
        return
    end

    local factionInventory = self:getFaction():getResourceInventory()
    local unitGenerationInfo = self.structureType:getUnitGenerationInfo(unitTypeId)

    for i, cost in ipairs(unitGenerationInfo.costs) do
        factionInventory:add(cost.resourceTypeId, cost.value)
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

	self.nextUnitGeneratedAt = nil
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

    local x, y = self:getFreeTileNearby()

    if (not x or not y) then
        print('No free tile found around the town hall.')
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

	if (self.structureType.updateInteract) then
		local interacted = self.structureType:updateInteract(self, deltaTime, interactor)

        if (not interacted) then
			print('Interact ended.')
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

    self.isRemoved = true

	local world = self:getWorld()

    for _, tile in pairs(self.tiles) do
        world:removeTile(tile.layerName, tile.x, tile.y)
    end

    world:updateCollisionMap()

	if (self.structureType.onRemove) then
		self.structureType:onRemove(self)
	end

	self:getFaction():removeStructure(self)

    self.events:trigger('structureRemoved')
end

return Structure
