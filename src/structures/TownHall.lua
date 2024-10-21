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

--- Called every time the structure updates (See GameConfig.structureUpdateTimeInSeconds)
--- @param structure Structure
function STRUCTURE:onTimedUpdate(structure)
	if (not self.lastVillagerGenerationTime) then
		self.lastVillagerGenerationTime = 0
	end

    self.lastVillagerGenerationTime = self.lastVillagerGenerationTime + GameConfig.structureUpdateTimeInSeconds

	if (self.lastVillagerGenerationTime < GameConfig.townHallVillagerGenerationTimeInSeconds) then
		return
	end

    self.lastVillagerGenerationTime = 0

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

return STRUCTURE
