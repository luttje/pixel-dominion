-- --- Represents the world map the player can interact with
-- --- @class WorldMap: InterfaceFragment
-- local WorldMap = DeclareClassWithBase('WorldMap', InterfaceFragment)

-- function WorldMap:initialize(config)
-- 	assert(self.world, 'World is required.')

-- 	table.Merge(self, config)

-- 	self.camera = { x = 0, y = 0 }
-- 	self.cameraWorldScale = 4
-- 	self.dragging = false
-- 	self.dragStart = { x = 0, y = 0 }

-- 	self:refreshMap()

-- 	return self
-- end

-- function WorldMap:refreshMap()
-- 	self.world:loadMap()
-- end

-- function WorldMap:screenToWorld(x, y, snapToTile)
-- 	if (snapToTile) then
-- 		return math.floor((x + self.camera.x * self.cameraWorldScale) / (GameConfig.tileSize * self.cameraWorldScale)),
-- 			math.floor((y + self.camera.y * self.cameraWorldScale) / (GameConfig.tileSize * self.cameraWorldScale))
-- 	end

-- 	return (x + self.camera.x * self.cameraWorldScale) / (GameConfig.tileSize * self.cameraWorldScale),
-- 		(y + self.camera.y * self.cameraWorldScale) / (GameConfig.tileSize * self.cameraWorldScale)
-- end

-- function WorldMap:worldToScreen(x, y)
-- 	return x * GameConfig.tileSize * self.cameraWorldScale - self.camera.x * self.cameraWorldScale,
-- 		y * GameConfig.tileSize * self.cameraWorldScale - self.camera.y * self.cameraWorldScale
-- end

-- function WorldMap:performUpdate(deltaTime)
-- 	local pointerX, pointerY = Input.GetPointerPosition()

-- 	self.world:update(deltaTime)

-- 	if (CurrentPlayer:isInputBlocked()) then
-- 		return
-- 	end

-- 	if (not love.mouse.isDown(1)) then
-- 		self.dragging = false
-- 		return
-- 	elseif (not self.dragging) then
-- 		self.dragging = true
-- 		self.dragStart.x = pointerX + self.camera.x * self.cameraWorldScale
-- 		self.dragStart.y = pointerY + self.camera.y * self.cameraWorldScale
-- 	end

-- 	if (self.dragging) then
-- 		local newX = (self.dragStart.x - pointerX) / self.cameraWorldScale
-- 		local newY = (self.dragStart.y - pointerY) / self.cameraWorldScale

-- 		self.camera.x = newX
-- 		self.camera.y = newY
-- 	end

-- 	-- Debug only. If space is down, show the x, y of the mouse in the world
-- 	if (love.keyboard.isDown('space')) then
-- 		local worldX, worldY = self:screenToWorld(pointerX, pointerY, true)
-- 		local unitOrStructure = self.world:getEntityUnderPosition(worldX, worldY)

-- 		if (unitOrStructure) then
-- 			TryCallIfNotOnCooldown(COMMON_COOLDOWNS.POINTER_INPUT, Times.clickInterval, function()
-- 				unitOrStructure:setSelected(not unitOrStructure.isSelected)

-- 				-- testing pathfinding
-- 				local pathPoints = SimpleTiled.findPath(unitOrStructure.x, unitOrStructure.y, 12, 7)

-- 				if (pathPoints) then
-- 					print('Path found!')
-- 					for _, point in ipairs(pathPoints) do
-- 						print(('Step: %d - x: %d - y: %d'):format(_, point.x, point.y))
-- 					end
-- 				else
-- 					print('No path found!')
-- 				end
-- 			end)
-- 		end

-- 		print('World X:', worldX, 'World Y:', worldY, 'Unit:', unitOrStructure)
-- 	end
-- end

-- function WorldMap:pushWorldSpace()
-- 	love.graphics.push()
-- 	love.graphics.translate(-self.camera.x, -self.camera.y)
-- end

-- function WorldMap:popWorldSpace()
-- 	love.graphics.pop()
-- end

-- function WorldMap:drawInWorldSpace(drawFunction)
-- 	self:pushWorldSpace()

-- 	drawFunction()

-- 	self:popWorldSpace()
-- end

-- function WorldMap:performDraw(x, y, width, height)
-- 	local translateX, translateY, scaleX, scaleY

-- 	translateX = -self.camera.x
-- 	translateY = -self.camera.y
-- 	scaleX = self.cameraWorldScale
-- 	scaleY = self.cameraWorldScale

-- 	self.world:draw(translateX, translateY, scaleX, scaleY)
-- end

-- return WorldMap

--- Displays all the resources the player has
--- @class ResourceBar: InterfaceFragment
local ResourceBar = DeclareClassWithBase('ResourceBar', InterfaceFragment)

function ResourceBar:initialize(config)
    assert(CurrentPlayer, 'Player is required.')

    table.Merge(self, config)

    self:refreshResources()

    return self
end

function ResourceBar:refreshResources()
    local faction = CurrentPlayer:getFaction()

    self.resourceValues = faction:getResourceValues()
end

function ResourceBar:performDraw(x, y, width, height)
	local resourcesValues = table.Values(self.resourceValues)
    local resourceX = x
    local resourceY = y
    local resourceWidth = width / #resourcesValues
    local resourceHeight = height

    -- Draw a background for the resource bar
    love.graphics.setColor(0.2, 0.5, 0.5)
    love.graphics.rectangle('fill', x, y, width, height)

    love.graphics.setFont(Fonts.resourceValue)
	local fontHeight = love.graphics.getFont():getHeight()

    for _, resourceValue in ipairs(resourcesValues) do
        local resourceType = resourceValue:getResourceType()
        local resourceAmount = resourceValue.value

        -- Draw the resource icon on the center-left
        local iconSize = resourceHeight * 0.8
        local iconX = resourceX + 10
        local iconY = resourceY + (resourceHeight - iconSize) / 2

        love.graphics.setColor(1, 1, 1)
        resourceType:draw(iconX, iconY, iconSize, iconSize)

        -- Draw the resource amount next to the icon
        love.graphics.setColor(0, 0, 0)
		love.graphics.print(resourceAmount, iconX + iconSize + 10, resourceY + (resourceHeight - fontHeight) / 2)

        resourceX = resourceX + resourceWidth
    end
end


return ResourceBar
