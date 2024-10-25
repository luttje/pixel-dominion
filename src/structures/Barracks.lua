local STRUCTURE = {}

STRUCTURE.id = 'barracks'
STRUCTURE.name = 'Barracks'

STRUCTURE.imagePath = 'assets/images/structures/barracks.png'
STRUCTURE.requiredResources = {
	wood = 90,
    stone = 40,
	gold = 10,
}

STRUCTURE.unitGenerationInfo = {
	{
		text = 'Train Warrior',
        icon = 'assets/images/icons/train.png',
		unitTypeId = 'warrior',
		timeInSeconds = 60,
        costs = {
            { resourceTypeId = 'food', value = 50 },
			{ resourceTypeId = 'gold', value = 10 },
		}
	}
}

STRUCTURE.structureTilesetInfo = {
	-- Barracks 1
    {
		-- Top
		{
			tilesetId = 2,
			tileId = 820,
			targetLayer = 'Dynamic_Top',
			offsetX = 0,
			offsetY = -1,
		},
		{
			tilesetId = 2,
			tileId = 821,
			targetLayer = 'Dynamic_Top',
			offsetX = 1,
			offsetY = -1,
        },
		{
			tilesetId = 2,
			tileId = 822,
			targetLayer = 'Dynamic_Top',
			offsetX = 2,
			offsetY = -1,
        },
		{
			tilesetId = 2,
			tileId = 823,
			targetLayer = 'Dynamic_Top',
			offsetX = 3,
			offsetY = -1,
        },
		-- Middle
		{
			tilesetId = 2,
			tileId = 920,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 0,
			offsetY = 0,
		},
		{
			tilesetId = 2,
			tileId = 921,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 1,
			offsetY = 0,
        },
		{
			tilesetId = 2,
			tileId = 922,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 2,
			offsetY = 0,
        },
		{
			tilesetId = 2,
			tileId = 923,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 3,
			offsetY = 0,
        },
        -- Bottom
		{
			tilesetId = 2,
			tileId = 1020,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 0,
			offsetY = 1,
        },
		{
			tilesetId = 2,
			tileId = 1021,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 1,
			offsetY = 1,
        },
		{
			tilesetId = 2,
			tileId = 1022,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 2,
			offsetY = 1,
        },
		{
			tilesetId = 2,
			tileId = 1023,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 3,
			offsetY = 1,
        },
    },
}

local sounds = {
	-- Sounds.swordsClashing1,
}

--- Called when the structure is created in the world
--- @param structure Structure
--- @param builders Unit[]
function STRUCTURE:onSpawn(structure, builders)
end

--- Returns whether the structure can be built by the faction. Resources are checked
--- before this function is called.
--- @param faction Faction
--- @return boolean
function STRUCTURE:canBeBuiltByFaction(faction)
	return true
end

return STRUCTURE
