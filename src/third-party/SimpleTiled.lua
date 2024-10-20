-- Original Source: https://github.com/karai17/Simple-Tiled-Implementation
-- Modified for our use case.
SimpleTiled = DeclareClass('SimpleTiled')

local sti = require("third-party.sti")

local loadedWorld

-- Load a map exported to Lua from Tiled
function SimpleTiled.loadMap(mapPath)
	loadedWorld = {
		layerCallbacks = {}
	}

	loadedWorld.map = sti(mapPath, { "box2d" })

	-- Prepare physics world with horizontal and vertical gravity
	loadedWorld.world = love.physics.newWorld(0, 0)

	-- Prepare collision objects
	loadedWorld.map:box2d_init(loadedWorld.world)

	-- -- Create a Custom Layer
	-- loadedWorld.map:addCustomLayer("Sprite Layer", 3)

	-- -- Add data to Custom Layer
	-- local spriteLayer = loadedWorld.map.layers["Sprite Layer"]
	-- spriteLayer.sprites = {
	-- 	player = {
	-- 		image = love.graphics.newImage("assets/sprites/player.png"),
	-- 		x = 64,
	-- 		y = 64,
	-- 		r = 0,
	-- 	}
	-- }

	-- -- Update callback for Custom Layer
	-- function spriteLayer:update(dt)
	-- 	for _, sprite in pairs(self.sprites) do
	-- 		sprite.r = sprite.r + math.rad(90 * dt)
	-- 	end
	-- end

	-- -- Draw callback for Custom Layer
	-- function spriteLayer:draw()
	-- 	for _, sprite in pairs(self.sprites) do
	-- 		local x = math.floor(sprite.x)
	-- 		local y = math.floor(sprite.y)
	-- 		local r = sprite.r
	-- 		love.graphics.draw(sprite.image, x, y, r)
	-- 	end
	-- end

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
end

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
--- @return table<number, table<number, number>>
function SimpleTiled.getCollisionMap()
	local collisionMap = {}

	if (not loadedWorld) then
		assert(false, "No map loaded.")
		return collisionMap
	end

	local map = loadedWorld.map

	for y = 1, map.height do
		collisionMap[y] = {}

		for x = 1, map.width do
			collisionMap[y][x] = 0
		end
	end

	for _, layer in ipairs(map.layers) do
		if (layer.properties.collidable) then
			for y = 1, map.height do
				for x = 1, map.width do
					local tile = layer.data[y][x]

					if (tile) then
						-- If the tile has a property "collidable" set to true, then mark it as collidable
						if (tile.properties.collidable) then
							collisionMap[y][x] = 1
						end

						-- If the entire layer is collidable, then any tile will be marked as collidable
						if (layer.properties.collidable) then
							collisionMap[y][x] = 1
						end
					end
				end
			end
		end
	end

	-- Print the collision map for debugging
	-- for y, row in ipairs(collisionMap) do
	-- 	local rowString = ""

	-- 	for x, value in ipairs(row) do
	-- 		rowString = rowString .. value
	-- 	end

	-- 	print(rowString)
	-- end

	return collisionMap
end

return SimpleTiled
