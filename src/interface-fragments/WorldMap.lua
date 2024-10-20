--- Represents the world map the player can interact with
--- @class WorldMap: InterfaceFragment
local WorldMap = DeclareClassWithBase('WorldMap', InterfaceFragment)

function WorldMap:initialize(config)
	assert(self.world, 'World is required.')

	table.Merge(self, config)

	self.camera = { x = 0, y = 0 }
	self.cameraWorldScale = 4
	self.dragging = false
	self.dragStart = { x = 0, y = 0 }

	self:refreshMap()

	return self
end

function WorldMap:refreshMap()
	self.world:loadMap()
end

function WorldMap:screenToWorld(x, y, snapToTile)
	if (snapToTile) then
		return math.floor((x + self.camera.x * self.cameraWorldScale) / (GameConfig.tileSize * self.cameraWorldScale)),
			math.floor((y + self.camera.y * self.cameraWorldScale) / (GameConfig.tileSize * self.cameraWorldScale))
	end

	return (x + self.camera.x * self.cameraWorldScale) / (GameConfig.tileSize * self.cameraWorldScale),
		(y + self.camera.y * self.cameraWorldScale) / (GameConfig.tileSize * self.cameraWorldScale)
end

function WorldMap:worldToScreen(x, y)
	return x * GameConfig.tileSize * self.cameraWorldScale - self.camera.x * self.cameraWorldScale,
		y * GameConfig.tileSize * self.cameraWorldScale - self.camera.y * self.cameraWorldScale
end

function WorldMap:performUpdate(deltaTime)
	local pointerX, pointerY = Input.GetPointerPosition()

	self.world:update(deltaTime)

	if (CurrentPlayer:isInputBlocked()) then
		return
	end

	if (not love.mouse.isDown(1)) then
		self.dragging = false
		return
	elseif (not self.dragging) then
		self.dragging = true
		self.dragStart.x = pointerX + self.camera.x * self.cameraWorldScale
		self.dragStart.y = pointerY + self.camera.y * self.cameraWorldScale
	end

	if (self.dragging) then
		local newX = (self.dragStart.x - pointerX) / self.cameraWorldScale
		local newY = (self.dragStart.y - pointerY) / self.cameraWorldScale

		self.camera.x = newX
		self.camera.y = newY
	end

	-- Debug only. If space is down, show the x, y of the mouse in the world
	if (love.keyboard.isDown('space')) then
		local worldX, worldY = self:screenToWorld(pointerX, pointerY, true)
		print('World X:', worldX, 'World Y:', worldY)
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
	local translateX, translateY, scaleX, scaleY

	translateX = -self.camera.x
	translateY = -self.camera.y
	scaleX = self.cameraWorldScale
	scaleY = self.cameraWorldScale

	self.world:draw(translateX, translateY, scaleX, scaleY)
end

return WorldMap
