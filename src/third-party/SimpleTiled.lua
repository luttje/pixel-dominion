-- Original Source: https://github.com/karai17/Simple-Tiled-Implementation
-- Modified for our use case.
SimpleTiled = DeclareClass('SimpleTiled')

local sti = require("third-party.sti")

local loadedWorld

-- Load a map exported to Lua from Tiled
function SimpleTiled.loadMap(mapPath)
	loadedWorld = {}

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

	if (GameConfig.MapLayersToRemove) then
		for _, layerName in ipairs(GameConfig.MapLayersToRemove) do
			loadedWorld.map:removeLayer(layerName)
		end
	end
end

-- Update the map
function SimpleTiled.update(dt)
	if (not loadedWorld) then
		return
	end

	loadedWorld.map:update(dt)
end

-- Draw the map
function SimpleTiled.draw(translateX, translateY, scaleX, scaleY)
	if (not loadedWorld) then
		return
	end

	-- Draw the map and all objects within
	love.graphics.setColor(1, 1, 1)
	loadedWorld.map:draw(translateX, translateY, scaleX, scaleY)

	-- Draw Collision Map (useful for debugging)
	love.graphics.setColor(1, 0, 0)
	loadedWorld.map:box2d_draw(translateX, translateY, scaleX, scaleY)
end

return SimpleTiled
