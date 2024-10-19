--- Represents the world map the player can interact with
--- @class WorldMap: InterfaceFragment
local WorldMap = DeclareClassWithBase('WorldMap', InterfaceFragment)

local TILE_SIZE = 32

function WorldMap:initialize(config)
	table.Merge(self, config)

	self.camera = { x = 0, y = 0 }
	self.dragging = false
	self.dragStart = { x = 0, y = 0 }

	self:refreshMap()

	return self
end

function WorldMap:refreshMap()
	self.worldData, self.worldBounds = RegionManager:getWorldDataForPlayer(CurrentPlayer)

	-- Set initial camera position to center on the hut, noting that the bottom half of the screen
	-- is covered by the interface
	self.focalHeight = self.focalHeight or (love.graphics.getHeight() * .6)
	self:setFocalHeight(self.focalHeight, true)
end

--- Sets the focal height of the map, which is the height of the map that is visible
--- without being obscured by the interface.
--- Optionally this also repositions the camera to center on the start position.
--- @param height number The height of the focal area
--- @param recenterCamera? boolean Whether to recenter the camera
function WorldMap:setFocalHeight(height, recenterCamera)
	self.focalHeight = height

	if (recenterCamera) then
		self.camera.x = self.worldData.homePosition.x * TILE_SIZE - (self:getWidth() * .5)
		self.camera.y = self.worldData.homePosition.y * TILE_SIZE -
			(self.focalHeight * .6) -- TODO: Fix this so it's actually centered

		-- self:doCameraMoved()
	end
end

--- Returns the focal height of the map
--- @return number
function WorldMap:getFocalHeight()
	return self.focalHeight
end

--- Checks if a scene canvas is prepared and prepares it if not.
--- Also releases the scene canvas if a new one with a different size is needed.
function WorldMap:prepareScenes()
	local width, height = self:getSize()

	if (not self._scene
			or self._scene:getWidth() ~= width
			or self._scene:getHeight() ~= height
		) then
		if (self._scene) then
			self._scene:release()
		end

		self._scene = love.graphics.newCanvas(width, height)
	end

	-- In any case we clear the scene canvas
	love.graphics.setCanvas(self._scene)
	love.graphics.clear()
end

--- Returns the tile name with the given x and y coordinates
--- @param tileX number The x coordinate of the tile
--- @param tileY number The y coordinate of the tile
--- @return string
function WorldMap:getTileName(tileX, tileY)
	return tileX .. ',' .. tileY
end

function WorldMap:worldToScreen(x, y)
	return x * TILE_SIZE - self.camera.x, y * TILE_SIZE - self.camera.y
end

function WorldMap:screenToWorld(x, y, snapToTile)
	if (snapToTile) then
		return math.floor((x + self.camera.x) / TILE_SIZE), math.floor((y + self.camera.y) / TILE_SIZE)
	end

	return (x + self.camera.x) / TILE_SIZE, (y + self.camera.y) / TILE_SIZE
end

function WorldMap:performUpdate(deltaTime)
	local pointerX, pointerY = Input.GetPointerPosition()

	if (CurrentPlayer:isInputBlocked()) then
		return
	end

	if (not love.mouse.isDown(1)) then
		self.dragging = false
		return
	elseif (not self.dragging) then
		if (pointerY > self.focalHeight) then
			-- Don't drag if we're not in the focal area (clicking actions or something)
			return
		end

		self.dragging = true
		self.dragStart.x = pointerX + self.camera.x
		self.dragStart.y = pointerY + self.camera.y
	end

	if (self.dragging) then
		local newX = self.dragStart.x - pointerX
		local newY = self.dragStart.y - pointerY

		-- Keep the camera within the unlocked area
		-- local tileInCenterX = math.floor((newX + love.graphics.getWidth() * 0.5) / TILE_SIZE)
		-- local tileInCenterY = math.floor((newY + self.focalHeight) / TILE_SIZE)

		-- local bounds = self:getUnlockedBounds(self.unlockBufferTileRadius)

		-- local moved = false

		-- if (tileInCenterX >= bounds.x and tileInCenterX < bounds.x + bounds.width) then
		self.camera.x = newX
		-- 	moved = true
		-- end

		-- if (tileInCenterY >= bounds.y and tileInCenterY < bounds.y + bounds.height) then
		self.camera.y = newY
		-- 	moved = true
		-- end

		-- if (moved) then
		-- self:doCameraMoved()
		-- end
	end
end

-- TODO: Don't draw the entire map, only the visible part
function WorldMap:drawLayerTile(layer, tile, tileX, tileY)
	local tileWidth = tile.tileWidth or TILE_SIZE
	local tileHeight = tile.tileHeight or TILE_SIZE

	tileX = tileX or tile.x
	tileY = tileY or tile.y

	local scaleX, scaleY = 1, 1

	if (tile.imageWidth or tile.imageSize) then
		scaleX = (tileWidth / tile.image:getWidth()) *
			math.ParsePercentageToScale(tile.imageWidth or tile.imageSize, tileWidth)
	end

	if (tile.imageHeight or tile.imageSize) then
		scaleY = (tileHeight / tile.image:getHeight()) *
			math.ParsePercentageToScale(tile.imageHeight or tile.imageSize, tileHeight)
	end

	if (not layer.withoutShadows) then
		-- Draw simple shadow offset using scale and sheer on the image
		love.graphics.setColor(0, 0, 0, 0.5)

		love.graphics.draw(
			tile.image,
			(tileX * tileWidth) + tileWidth * 0.1,
			(tileY * tileHeight) + tileHeight * 0.1,
			0,
			scaleX, scaleY,
			0, 0,
			0.2, 0.2)
	end

	if (tile.color) then
		love.graphics.setColor(tile.color())
	else
		love.graphics.setColor(1, 1, 1, 1)
	end

	love.graphics.draw(
		tile.image,
		tileX * tileWidth,
		tileY * tileHeight,
		0,
		scaleX,
		scaleY)

	-- -- TODO: Debug only, we draw the tileX and Y on the tile
	-- love.graphics.printf(
	--     tileX .. ',' .. tileY,
	--     (tileX * tileWidth),
	-- 	(tileY * tileHeight),
	--     tileWidth,
	--     'center')
	-- And outline it
	-- love.graphics.rectangle('line', tileX * tileWidth, tileY * tileHeight, tileWidth, tileHeight)

	local screenTileMinX, screenTileMinY = self:screenToWorld(0, 0)
	local screenTileMaxX, screenTileMaxY = self:screenToWorld(love.graphics.getWidth(), self.focalHeight)

	-- Draw a white circle clamp to the edge of the screen, indicating the hut is off screen in that direction
	if (tile.hasOffScreenIndicator
			and (tileX < screenTileMinX
				or tileX > screenTileMaxX
				or tileY < screenTileMinY
				or tileY > screenTileMaxY)) then
		table.insert(self.tileOverlayDraws, function()
			local finalX, finalY = (tileX * tileWidth) + (tileWidth * .5), (tileY * tileHeight) + (tileHeight * .5)
			local arrows = {}

			love.graphics.setColor(1, 0, 0, 0.5)

			if (tileX < screenTileMinX) then
				finalX = (screenTileMinX * tileWidth) + (tileWidth * 2)

				table.insert(arrows, 'left')
			end

			if (tileX > screenTileMaxX) then
				finalX = (screenTileMaxX * tileWidth) - (tileWidth * 2)

				table.insert(arrows, 'right')
			end

			if (tileY < screenTileMinY) then
				finalY = (screenTileMinY * tileHeight) + (tileHeight * 2)

				table.insert(arrows, 'up')
			end

			if (tileY > screenTileMaxY) then
				finalY = (screenTileMaxY * tileHeight) - tileHeight

				table.insert(arrows, 'down')
			end

			for _, arrow in ipairs(arrows) do
				if (arrow == 'left') then
					love.graphics.polygon(
						'fill',
						finalX - tileWidth - 10, finalY,
						finalX - tileWidth, finalY - 10,
						finalX - tileWidth, finalY + 10
					)
				elseif (arrow == 'right') then
					love.graphics.polygon(
						'fill',
						finalX + tileWidth + 10, finalY,
						finalX + tileWidth, finalY - 10,
						finalX + tileWidth, finalY + 10
					)
				elseif (arrow == 'up') then
					love.graphics.polygon(
						'fill',
						finalX, finalY - tileHeight - 10,
						finalX - 10, finalY - tileHeight,
						finalX + 10, finalY - tileHeight
					)
				elseif (arrow == 'down') then
					love.graphics.polygon(
						'fill',
						finalX, finalY + tileHeight + 10,
						finalX - 10, finalY + tileHeight,
						finalX + 10, finalY + tileHeight
					)
				end
			end

			love.graphics.setColor(1, 1, 1, 0.5)
			love.graphics.circle('fill', finalX, finalY, scaleX * tileWidth * 2)

			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(
				tile.image,
				finalX - tileWidth * 0.5,
				finalY - tileHeight * 0.5,
				0,
				scaleX * .5,
				scaleY * .5)
		end)
	end
end

function WorldMap:pushWorldSpace()
	love.graphics.push()
	love.graphics.translate(-self.camera.x, -self.camera.y)
end

function WorldMap:popWorldSpace()
	love.graphics.pop()
end

function WorldMap:drawInWorldSpace(drawFunction)
	self:pushWorldSpace()

	drawFunction()

	self:popWorldSpace()
end

function WorldMap:performDraw(x, y, width, height)
	self:prepareScenes()

	love.graphics.clear()
	love.graphics.setFont(Fonts.debug)

	self.tileOverlayDraws = {}

	self:drawInWorldSpace(function()
		love.graphics.setCanvas(self._scene)

		for _, layer in ipairs(self.worldData.layers) do
			for _, tile in ipairs(layer.tiles) do
				if (tile.untilX and tile.untilY) then
					for tileX = tile.x, tile.untilX do
						for tileY = tile.y, tile.untilY do
							self:drawLayerTile(layer, tile, tileX, tileY)
						end
					end
				else
					self:drawLayerTile(layer, tile)
				end
			end
		end

		love.graphics.setCanvas()
	end)

	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.draw(self._scene, x, y, 0, width / self._scene:getWidth(),
		height / self._scene:getHeight())
end

return WorldMap
