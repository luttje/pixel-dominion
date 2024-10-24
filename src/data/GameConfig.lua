local GameConfig = {}

--[[
	General game settings
--]]

--- The name of the game.
--- @type string
GameConfig.name = 'Unnamed RTS'

--[[
	Game functionality settings
--]]

--- The names of layers to remove from the map.
--- Useful to disable the ground grid or debug layers.
--- @type table
GameConfig.mapLayersToRemove = {
    -- 'GroundGrid',
	'DesignTimeOnly',
}

--- Width and height of the map tiles in pixels.
--- @type number
GameConfig.tileSize = 8

--- How long it takes for a unit to move from one tile to another in seconds.
--- @type number
GameConfig.unitMoveTimeInSeconds = 0.5

--- How long it takes to take a single supply from a resource in seconds.
--- @type number
GameConfig.resourceHarvestTimeInSeconds = 2

--- How long between a structure calls its update function in seconds.
--- @type number
GameConfig.structureUpdateTimeInSeconds = 0.5

--- How many seconds to generate a villager
--- @type number
GameConfig.townHallVillagerGenerationTimeInSeconds = 15

--- How many supplies a unit can carry.
--- @type number
GameConfig.unitSupplyCapacity = 5

--- How long in between animation frames in seconds.
--- @type number
GameConfig.animationFrameTimeInSeconds = 0.2

--- The pathing offsets for looking around interactables.
--- @type table
GameConfig.unitPathingOffsets = {
	-- Orthagonal
	{ x = 0, y = 1 },
	{ x = -1, y = 0 },
	{ x = 1, y = 0 },
    { x = 0,  y = -1 },
	-- Diagonal
	{ x = -1, y = -1 },
	{ x = 1, y = -1 },
	{ x = -1, y = 1 },
	{ x = 1, y = 1 },
}

--- The tile ids that are spawnpoints for factions.
--- @type table
GameConfig.factionSpawnTileIds = {
	{
		tilesetId = 1, -- #forest
		tileId = 226,
	},
	{
		tilesetId = 1,
		tileId = 227,
	},
	{
		tilesetId = 1,
		tileId = 228,
	},
	{
		tilesetId = 1,
		tileId = 229,
	},
	{
		tilesetId = 1,
		tileId = 230,
	},
}

--[[
	Debug/testing options
--]]

--- Dump the collision map to the console for debugging and draw the tiled
--- collision map in red on the map.
--- @type boolean
GameConfig.debugCollisionMap = false

--- Disable the tutorial for quick testing.
--- @type boolean
-- GameConfig.disableTutorial = true -- unused atm

return GameConfig
