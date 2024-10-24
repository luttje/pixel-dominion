local STRUCTURE = {}

STRUCTURE.id = 'town_hall'
STRUCTURE.name = 'Town Hall'

-- Don't allow construction of town halls for now
STRUCTURE.isInternal = true

STRUCTURE.imagePath = 'assets/images/structures/town-hall.png'

STRUCTURE.structureTilesetInfo = {
	-- Town Hall 1
	{
		-- Top of the town hall
		{
			tilesetId = 2,
			tileId = 517,
			targetLayer = 'Dynamic_Top',
			offsetX = 0,
			offsetY = -1,
		},
		{
			tilesetId = 2,
			tileId = 518,
			targetLayer = 'Dynamic_Top',
			offsetX = 1,
			offsetY = -1,
		},
		{
			tilesetId = 2,
			tileId = 519,
			targetLayer = 'Dynamic_Top',
			offsetX = 2,
			offsetY = -1,
		},
		-- Bottom of the town hall
		{
			tilesetId = 2,
			tileId = 617,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 0,
			offsetY = 0,
		},
		{
			tilesetId = 2,
			tileId = 618,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 1,
			offsetY = 0,
        },
		{
			tilesetId = 2,
			tileId = 619,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 2,
			offsetY = 0,
		},
    },
}

--- Called when the structure is created in the world
--- @param structure Structure
--- @param builders Unit[]
function STRUCTURE:onSpawn(structure, builders)
	structure.lastUnitGenerationTime = 0

	-- Start with 1 villager
    self:generateUnit(structure)
end

--- Called every time the structure updates (See GameConfig.structureUpdateTimeInSeconds)
--- @param structure Structure
function STRUCTURE:onTimedUpdate(structure)
	local faction = structure:getFaction()
    local units = faction:getUnits()
	local housing = faction:getResourceInventory():getValue('housing')

	if (#units >= housing or not structure.lastUnitGenerationTime) then
		structure.lastUnitGenerationTime = nil

		return
	end

    structure.lastUnitGenerationTime = structure.lastUnitGenerationTime + GameConfig.structureUpdateTimeInSeconds

	if (structure.lastUnitGenerationTime < GameConfig.structureUnitGenerationTimeInSeconds) then
		return
	end

    structure.lastUnitGenerationTime = 0

    self:generateUnit(structure)
end

--- Generates a villager
--- @param structure Structure
function STRUCTURE:generateUnit(structure)
	local faction = structure:getFaction()
    local units = faction:getUnits()
	local housing = faction:getResourceInventory():getValue('housing')

	if (#units >= housing) then
		return
	end

    local x, y = structure:getFreeTileNearby()

    if (not x or not y) then
        print('No free tile found around the town hall.')
        return
    end

	faction:spawnUnit(
        UnitTypeRegistry:getUnitType('villager'),
        x, y
	)
end

--- Draws how much progress has been made generating a villager
--- @param structure Structure
--- @param x number
--- @param y number
--- @param radius number
function STRUCTURE:drawUnitProgress(structure, x, y, radius)
	love.graphics.drawProgressCircle(
		x,
		y,
		radius,
		structure.lastUnitGenerationTime / GameConfig.structureUnitGenerationTimeInSeconds)

	-- Draw the villager icon over the progress circle
	local padding = Sizes.padding()
	local iconWidth = radius * 2 - padding * 2
	local iconHeight = radius * 2 - padding * 2

	love.graphics.setColor(1, 1, 1)
	UnitTypeRegistry:getUnitType('villager'):drawHudIcon(nil, x - radius + padding, y - radius + padding, iconWidth, iconHeight)
end

--- Called after the structure is drawn on screen
--- @param structure Structure
--- @param minX number
--- @param minY number
--- @param maxX number
--- @param maxY number
function STRUCTURE:postDrawOnScreen(structure, minX, minY, maxX, maxY)
	-- Commented because its easier on mobile if structures can't be selected
	-- if (not structure:getIsSelected()) then
	-- 	return
	-- end

	if (structure.lastUnitGenerationTime) then
		local x = minX + (maxX - minX) * .5
		local y = minY + (maxY - minY) * .5
		local radius = (maxX - minX) * .2

		self:drawUnitProgress(structure, x, y, radius)
	end
end

--- When an structure is interacted with by a unit.
--- @param structure Structure
--- @param deltaTime number
--- @param interactor Interactable
function STRUCTURE:updateInteract(structure, deltaTime, interactor)
    -- Take any resources from the unit and place them in the faction inventory
    local inventory = interactor:getResourceInventory()

    if (inventory:getCurrentResources() == 0) then
        print('unit has no resources.')
		interactor:stop()
        return
    end

    local faction = structure:getFaction()
    local factionInventory = faction:getResourceInventory()
    local lastResourceInstance = interactor:getLastResourceInstance()

	assert(lastResourceInstance, 'No last resource instance found.')

    for resourceTypeId, resourceValue in pairs(inventory:getAll()) do
        factionInventory:add(resourceTypeId, resourceValue.value)
    end

    inventory:clear()

    -- First go back to the last resource we came from if it has any supply left
    if (lastResourceInstance:getSupply() > 0) then
        interactor:commandTo(lastResourceInstance.x, lastResourceInstance.y, lastResourceInstance)

        return
    end

	-- Find the nearest resource instance of the same type
    local nearestResourceInstance = CurrentWorld:findNearestResourceInstance(lastResourceInstance:getResourceType(), structure.x, structure.y)

    if (not nearestResourceInstance) then
        print('No resource instance found. Stopping')
		interactor:stop()
        return
    end

    interactor:commandTo(nearestResourceInstance.x, nearestResourceInstance.y, nearestResourceInstance)
end

--- Returns whether the structure can be built by the faction. Resources are checked
--- before this function is called.
--- @param faction Faction
--- @return boolean
function STRUCTURE:canBeBuiltByFaction(faction)
	return false
end

return STRUCTURE
