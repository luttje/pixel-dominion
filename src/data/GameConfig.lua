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

--- The scaling factor for everything in the world map.
--- @type number
GameConfig.worldMapCameraScale = 4

--- The names of layers to remove from the map.
--- Useful to disable the ground grid or debug layers.
--- @type table
GameConfig.mapLayersToRemove = {
    -- 'GroundGrid',
	'DesignTimeOnly',
}

--- The fog of war layer name.
--- @type string
GameConfig.fogOfWarLayerName = 'FogOfWar'

--- The tileset id for the fog of war.
--- @type number
GameConfig.fogOfWarTilesetId = 3

--- The tile id for the fog of war.
--- @type number
GameConfig.fogOfWarTileId = 0 -- TODO: We have tiles for all edges, corners, etc. Use them.

--- Width and height of the map tiles in pixels.
--- @type number
GameConfig.tileSize = 8

--- How many supplies a unit can carry.
--- @type number
GameConfig.unitSupplyCapacity = 5

--- The pathing offsets for looking around interactables.
--- @type table
GameConfig.tileSearchOffsets = {
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

--- The boundary of the tile search offsets.
--- @type {x:number, y:number, width:number, height:number}
GameConfig.tileSearchOffsetsBoundary = {
	x = -1,
	y = -1,
	width = 3,
	height = 3,
}

-- Assert that no mistakes were made in the tile search offsets above.
do
	local boundary = GameConfig.tileSearchOffsetsBoundary
	for _, offset in ipairs(GameConfig.tileSearchOffsets) do
		assert(offset.x >= boundary.x and offset.x < boundary.x + boundary.width, 'Tile search offset x out of bounds')
		assert(offset.y >= boundary.y and offset.y < boundary.y + boundary.height, 'Tile search offset y out of bounds')
	end
end

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
	Game time/speed settings
--]]

--- The game speed, all other time values are sped up by this.
--- @type number
GameConfig.gameSpeed = 1

--- @alias GameTimeGetter fun():number

--- Helper function which returns a function that returns the time, sped up by a game speed factor.
--- @param seconds number
--- @return GameTimeGetter
function GameConfig.timeInSeconds(seconds)
    return function()
        return seconds / GameConfig.gameSpeed
    end
end

--- How long the user has to hold down to interact with something or move to a tile.
--- @type number
GameConfig.interactHoldTimeInSeconds = 0.3

--- How long it takes for a unit to move from one tile to another in seconds.
--- @type GameTimeGetter
GameConfig.unitMoveTimeInSeconds = GameConfig.timeInSeconds(0.5)

--- How long it takes to take a single supply from a resource in seconds.
--- @type GameTimeGetter
GameConfig.resourceHarvestTimeInSeconds = GameConfig.timeInSeconds(2)

--- How long between a structure calls its update function in seconds.
--- @type GameTimeGetter
GameConfig.structureUpdateTimeInSeconds = GameConfig.timeInSeconds(0.5)

--- How many seconds between dealing damage to a structure or unit.
--- @type GameTimeGetter
GameConfig.interactableDamageTimeInSeconds = GameConfig.timeInSeconds(1)

--- How long in between animation frames in seconds.
--- @type GameTimeGetter
GameConfig.animationFrameTimeInSeconds = GameConfig.timeInSeconds(0.2)

--- How long it takes for a unit already moving along a path to update its path again (costly).
--- @type GameTimeGetter
GameConfig.unitPathUpdateIntervalInSeconds = math.huge -- never for now, lets see what happens (besides walking through walls that were just placed)

--[[
	Debug/testing options
--]]

--- Dump the collision map to the console for debugging and draw the tiled
--- collision map in red on the map.
--- @type boolean
GameConfig.debugCollisionMap = false

--- Cheats to speed up testing, like adding villagers, resources, etc.
--- @type boolean
GameConfig.debugCheatsEnabled = true

--- Disable the tutorial for quick testing.
--- @type boolean
-- GameConfig.disableTutorial = true -- unused atm

--- Disable music for less distraction during testing.
--- @type boolean
GameConfig.disableMusic = true

--- Disable the fog of war for testing.
--- @type boolean
GameConfig.disableFogOfWar = false

return GameConfig
