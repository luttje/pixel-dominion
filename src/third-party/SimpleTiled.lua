-- Original Source: https://github.com/karai17/Simple-Tiled-Implementation
-- Modified for our use case.
SimpleTiled = DeclareClass('SimpleTiled')

local Sti = require("third-party.sti")
local Grid = require("third-party.jumper.grid")
local Pathfinder = require("third-party.jumper.pathfinder")

local loadedWorld

-- Load a map exported to Lua from Tiled
function SimpleTiled.loadMap(mapPath)
	loadedWorld = {
		layerCallbacks = {}
	}

	loadedWorld.map = Sti(mapPath, { "box2d" })

	-- Prepare physics world with horizontal and vertical gravity
	loadedWorld.world = love.physics.newWorld(0, 0)

	-- Prepare collision objects
	loadedWorld.map:box2d_init(loadedWorld.world)

	-- Call update and draw callbacks for these layers
	local layersWithCallbacks = {
		"Dynamic_Units",
		"Dynamic_Structures"
	}

	for _, layerName in ipairs(layersWithCallbacks) do
		local layer = loadedWorld.map.layers[layerName]

		if (layer) then
			function layer:update(dt)
				if (not loadedWorld.layerCallbacks[layerName] or not loadedWorld.layerCallbacks[layerName].update) then
					return
				end

				for _, callback in ipairs(loadedWorld.layerCallbacks[layerName].update) do
					callback(dt)
				end
			end

			function layer:draw()
				if (not loadedWorld.layerCallbacks[layerName] or not loadedWorld.layerCallbacks[layerName].draw) then
					return
				end

				for _, callback in ipairs(loadedWorld.layerCallbacks[layerName].draw) do
					callback()
				end
			end
		end
	end

	if (GameConfig.mapLayersToRemove) then
		for _, layerName in ipairs(GameConfig.mapLayersToRemove) do
			loadedWorld.map:removeLayer(layerName)
		end
	end

	-- Cache the static collision map
	local collisionMap, walkable = SimpleTiled.getCollisionMap()

	if (GameConfig.debugCollisionMap) then
		for y, row in ipairs(collisionMap) do
			local rowString = ""

			for x, value in ipairs(row) do
				rowString = rowString .. value
			end

			print(rowString)
		end
	end

	loadedWorld.collisionGrid = Grid(collisionMap)
	loadedWorld.pathfinder = Pathfinder(loadedWorld.collisionGrid, 'ASTAR', walkable)
end

--- Registers a callback for a specific layer and callback type.
--- @param layerName string
--- @param callbackType 'update' | 'draw'
--- @param callback function
function SimpleTiled.registerLayerCallback(layerName, callbackType, callback)
	if (not loadedWorld) then
		assert(false, "No map loaded.")
		return
	end

	if (not loadedWorld.layerCallbacks[layerName]) then
		loadedWorld.layerCallbacks[layerName] = {}
	end

	if (not loadedWorld.layerCallbacks[layerName][callbackType]) then
		loadedWorld.layerCallbacks[layerName][callbackType] = {}
	end

	table.insert(loadedWorld.layerCallbacks[layerName][callbackType], callback)
end

function SimpleTiled.update(deltaTime)
	if (not loadedWorld) then
		assert(false, "No map loaded.")
		return
	end

	loadedWorld.map:update(deltaTime)
end

function SimpleTiled.draw(translateX, translateY, scaleX, scaleY)
	if (not loadedWorld) then
		assert(false, "No map loaded.")
		return
	end

	-- Draw the map and all objects within
	love.graphics.setColor(1, 1, 1)
	loadedWorld.map:draw(translateX, translateY, scaleX, scaleY)

	-- Draw Collision Map (useful for debugging)
	love.graphics.setColor(1, 0, 0)
	loadedWorld.map:box2d_draw(translateX, translateY, scaleX, scaleY)
end

--- Returns the collision map for the loaded map based on the "collidable" property of the layers.
--- Additionally it returns the number representing a walkable tile (always 0).
--- @return table<number, table<number, number>>, number
function SimpleTiled.getCollisionMap()
	local collisionMap = {}

	if (not loadedWorld) then
		assert(false, "No map loaded.")
		return collisionMap
	end

	local map = loadedWorld.map
	local walkable, notWalkable = 0, 1

	for y = 1, map.height do
		collisionMap[y] = {}

		for x = 1, map.width do
			collisionMap[y][x] = walkable
		end
	end

	for _, layer in ipairs(map.layers) do
		if (layer.data) then
			for y = 1, map.height do
				for x = 1, map.width do
					local tile = layer.data[y][x]

					if (tile) then
						-- If the tile has a property "collidable" set to true, then mark it as collidable
						-- Or if the entire layer is collidable, then any tile will be marked as collidable
						if (tile.properties.collidable or layer.properties.collidable) then
							collisionMap[y][x] = notWalkable
						end
					end
				end
			end
		end
	end

	return collisionMap, walkable
end

--- Uses the pathfinder to find a path from the start to the end position.
--- @param startX number # The start X (0-based)
--- @param startY number # The start Y (0-based)
--- @param endX number # The end X (0-based)
--- @param endY number # The end Y (0-based)
--- @return table<number, table<number, number>> | nil # A table of path points (0-based) or nil if no path was found
function SimpleTiled.findPath(startX, startY, endX, endY)
	if (not loadedWorld) then
		assert(false, "No map loaded.")
		return
	end

	-- The path finder works with 1-based indexes while the map is 0-based
	startX = startX + 1
	startY = startY + 1
	endX = endX + 1
	endY = endY + 1

	local path = loadedWorld.pathfinder:getPath(startX, startY, endX, endY)

	if (not path) then
		return nil
	end

	-- Convert back to 0-based indexes
	local points = {}

	for node, count in path:nodes() do
		table.insert(points, { x = node:getX() - 1, y = node:getY() - 1 })
	end

	return points
end

return SimpleTiled
