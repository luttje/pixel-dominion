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
}

--- Width and height of the map tiles in pixels.
--- @type number
GameConfig.tileSize = 8

--[[
	Debug/testing options
--]]

--- Dump the collision map to the console for debugging.
--- @type boolean
GameConfig.debugCollisionMap = true

--- Disable the tutorial for quick testing.
--- @type boolean
GameConfig.disableTutorial = true

return GameConfig
