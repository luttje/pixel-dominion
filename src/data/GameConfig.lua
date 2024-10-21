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
    -- "GroundGrid",
	"DesignTimeOnly",
}

--- Width and height of the map tiles in pixels.
--- @type number
GameConfig.tileSize = 8

--- How long it takes for a unit to move from one tile to another in milliseconds.
--- @type number
GameConfig.unitMoveTimeInSeconds = 0.5

--[[
	Debug/testing options
--]]

--- Dump the collision map to the console for debugging and draw the tiled
--- collision map in red on the map.
--- @type boolean
GameConfig.debugCollisionMap = false

--- Disable the tutorial for quick testing.
--- @type boolean
GameConfig.disableTutorial = true

return GameConfig
