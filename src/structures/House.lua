local STRUCTURE = {}

local GRANTS_HOUSING = 5

STRUCTURE.id = 'house'
STRUCTURE.name = 'House'

STRUCTURE.imagePath = 'assets/images/structures/house.png'

STRUCTURE.worldTilesetInfo = {
	-- House 1
	{
		-- Top of the house
		{
			tilesetId = 2,
			tileId = 414,
			targetLayer = 'Dynamic_Top',
			offsetX = 0,
			offsetY = -1,
		},
		{
			tilesetId = 2,
			tileId = 415,
			targetLayer = 'Dynamic_Top',
			offsetX = 1,
			offsetY = -1,
		},
		-- Bottom of the house
		{
			tilesetId = 2,
			tileId = 514,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 0,
			offsetY = 0,
		},
		{
			tilesetId = 2,
			tileId = 515,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 1,
			offsetY = 0,
        },
    },
}

--- Called when the structure is created in the world
--- @param structure Structure
function STRUCTURE:onSpawn(structure)
    -- Grant +5 housing to the faction
    structure:getFaction():getResourceInventory():add('housing', GRANTS_HOUSING)
end

--- Called when the structure is destroyed/removed from the world
--- @param structure Structure
function STRUCTURE:onRemove(structure)
	-- Remove the housing from the faction
	structure:getFaction():getResourceInventory():remove('housing', GRANTS_HOUSING)
end

--- Returns whether the structure can be built by the faction
--- @param faction Faction
--- @return boolean
function STRUCTURE:canBeBuiltByFaction(faction)
	return true
end

return STRUCTURE
