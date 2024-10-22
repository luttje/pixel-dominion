local STRUCTURE = {}

STRUCTURE.id = 'town_hall'
STRUCTURE.name = 'Town Hall'

STRUCTURE.imagePath = 'assets/images/structures/town-hall.png'

STRUCTURE.worldTilesetInfo = {
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
function STRUCTURE:onSpawn(structure)
	structure.lastVillagerGenerationTime = 0

	-- Start with 1 villager
    self:generateVillager(structure)
end

--- Called every time the structure updates (See GameConfig.structureUpdateTimeInSeconds)
--- @param structure Structure
function STRUCTURE:onTimedUpdate(structure)
	local faction = structure:getFaction()
    local units = faction:getUnits()
	local housing = faction:getResourceInventory():getValue('housing')

	if (#units >= housing or not structure.lastVillagerGenerationTime) then
		structure.lastVillagerGenerationTime = nil

		return
	end

    structure.lastVillagerGenerationTime = structure.lastVillagerGenerationTime + GameConfig.structureUpdateTimeInSeconds

	if (structure.lastVillagerGenerationTime < GameConfig.townHallVillagerGenerationTimeInSeconds) then
		return
	end

    structure.lastVillagerGenerationTime = 0

    self:generateVillager(structure)
end

--- Generates a villager
--- @param structure Structure
function STRUCTURE:generateVillager(structure)
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
        UnitTypeRegistry:getUnitType('builder'),
        x, y
	)
end

--- Draws how much progress has been made generating a villager
--- @param structure Structure
--- @param x number
--- @param y number
--- @param radius number
function STRUCTURE:drawVillagerProgress(structure, x, y, radius)
	love.graphics.drawProgressCircle(
		x,
		y,
		radius,
		structure.lastVillagerGenerationTime / GameConfig.townHallVillagerGenerationTimeInSeconds)

	-- Draw the villager icon over the progress circle
	local padding = Sizes.padding()
	local iconWidth = radius * 2 - padding * 2
	local iconHeight = radius * 2 - padding * 2

	love.graphics.setColor(1, 1, 1)
	UnitTypeRegistry:getUnitType('builder'):drawHudIcon(nil, x - radius + padding, y - radius + padding, iconWidth, iconHeight)
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

	if (structure.lastVillagerGenerationTime) then
		local x = minX + (maxX - minX) * .5
		local y = minY + (maxY - minY) * .5
		local radius = (maxX - minX) * .25

		self:drawVillagerProgress(structure, x, y, radius)
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
		return
	end

	local faction = structure:getFaction()
	local factionInventory = faction:getResourceInventory()
	local lastResourceType

	for resourceTypeId, resourceValue in pairs(inventory:getAll()) do
		factionInventory:add(resourceTypeId, resourceValue.value)

		lastResourceType = resourceValue:getResourceType()
	end

	inventory:clear()

	if (not lastResourceType) then
		return
	end

	local nearestResourceInstance = CurrentWorld:findNearestResourceInstance(lastResourceType, structure.x, structure.y)

	if (not nearestResourceInstance) then
		return
	end

	interactor:commandTo(nearestResourceInstance.x, nearestResourceInstance.y, nearestResourceInstance)
end

return STRUCTURE
