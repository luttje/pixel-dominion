local STRUCTURE = {}

STRUCTURE.id = 'lumber_camp'
STRUCTURE.name = 'Lumber Camp'

STRUCTURE.imagePath = 'assets/images/structures/lumber-camp.png'
STRUCTURE.requiredResources = {
	wood = 50,
    stone = 10,
}

STRUCTURE.dropOffForResources = {
	wood = 2, -- multiplied efficiency -- TODO: Might be confusing, since the town hall will be preferred for drop off if it's closer
}

-- --- @type UnitGenerationInfo[]
-- STRUCTURE.unitGenerationInfo = {
-- 	{
-- 		id = 'create_lumberjack',
-- 		text = 'Lumberjack',
-- 		icon = 'assets/images/icons/lumberjack.png',
-- 		unitTypeId = 'lumberjack',
-- 		generationTimeInSeconds = GameConfig.timeInSeconds(15),
-- 		costs = {
--			food = 25,
-- 		}
-- 	}
-- }

STRUCTURE.structureTilesetInfo = {
	-- Lumber Camp 1
	{
		-- Top of the lumber camp
		{
			tilesetId = 2,
			tileId = 1115,
			targetLayer = 'Dynamic_Top',
			offsetX = 0,
			offsetY = -1,
		},
		{
			tilesetId = 2,
			tileId = 1116,
			targetLayer = 'Dynamic_Top',
			offsetX = 1,
			offsetY = -1,
		},
		-- Bottom of the lumber camp
		{
			tilesetId = 2,
			tileId = 1215,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 0,
			offsetY = 0,
		},
		{
			tilesetId = 2,
			tileId = 1216,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 1,
			offsetY = 0,
		},
	},
}

--- Called when the structure is created in the world
--- @param structure Structure
--- @param builders? Unit[]
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
