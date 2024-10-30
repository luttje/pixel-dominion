local STRUCTURE = {}

STRUCTURE.id = 'town_hall'
STRUCTURE.name = 'Town Hall'

-- Don't allow construction of town halls for now
STRUCTURE.isInternal = true

STRUCTURE.imagePath = 'assets/images/structures/town-hall.png'

STRUCTURE.dropOffForResources = {
    wood = true,
    stone = true,
    food = true,
    gold = true,
}

--- @type UnitGenerationInfo[]
STRUCTURE.unitGenerationInfo = {
	{
		id = 'create_villager',
		text = 'Villager',
		icon = 'assets/images/icons/villager.png',
		unitTypeId = 'villager',
        generationTimeInSeconds = GameConfig.timeInSeconds(15),
        costs = {
			food = 25,
		}
	}
}

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
--- @param builders? Unit[]
function STRUCTURE:onSpawn(structure, builders)
	-- Start with 1 villager
    structure:generateUnit('villager')
end

--- Returns whether the structure can be built by the faction. Resources are checked
--- before this function is called.
--- @param faction Faction
--- @return boolean
function STRUCTURE:canBeBuiltByFaction(faction)
	return false
end

return STRUCTURE
