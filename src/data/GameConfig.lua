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

--- Width and height of the map tiles in pixels.
--- @type number
GameConfig.tileSize = 8

--- How many supplies a unit can carry.
--- @type number
GameConfig.unitSupplyCapacity = 5

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

return GameConfig
