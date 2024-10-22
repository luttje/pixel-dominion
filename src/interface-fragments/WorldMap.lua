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

	self:centerOnTownHall()

	return self
end

--- Centers the camera on the current player's faction's town hall
function WorldMap:centerOnTownHall()
	local townHall = CurrentPlayer:getFaction():getStructures()[1]

	assert(townHall, 'No town hall found.')

	self.camera.x = (townHall.x * GameConfig.tileSize) - (self:getWidth() * .5) / self.cameraWorldScale
	self.camera.y = (townHall.y * GameConfig.tileSize) - (self:getHeight() * .4) / self.cameraWorldScale

	-- Let's select it so players see that that will give them information about villager generation
	townHall:setSelected(true)
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

	if (CurrentPlayer:isWorldInputBlocked()) then
		return
	end

    -- Require both mouse buttons to be down to drag the camera (or two fingers on a touch screen)
    local wantsToDrag = (love.mouse.isDown(1) and love.mouse.isDown(2))
        or (#love.touch.getTouches() == 2)

    if (not wantsToDrag) then
		if (self.dragging) then
			TryCallIfNotOnCooldown(COMMON_COOLDOWNS.POINTER_INPUT_RELEASED, Times.clickInterval, function()
            	self.dragging = false
			end)
        elseif (love.mouse.isDown(1)) then
			local worldX, worldY = self:screenToWorld(pointerX, pointerY, true)
            local interactable = self.world:getInteractableUnderPosition(worldX, worldY)

            -- If we clicked on a unit, structure or resource instance, clear if our current selection is not the same
            if (interactable and interactable.isSelectable) then
				if (CurrentPlayer:isSameTypeAsSelected(interactable)) then
					TryCallIfNotOnCooldown(COMMON_COOLDOWNS.POINTER_INPUT, Times.clickInterval, function()
						-- If the unit is selected, deselect it
						if (interactable.isSelected) then
							interactable:setSelected(false)
						else
							-- If the unit is not selected, select it
							interactable:setSelected(true)
						end
					end)
				else
					-- If the unit is not the same type, deselect all units and select this one
					TryCallIfNotOnCooldown(COMMON_COOLDOWNS.POINTER_INPUT, Times.clickInterval, function()
						CurrentPlayer:clearSelectedInteractables()
						interactable:setSelected(not interactable.isSelected)
					end)
				end
			else
				TryCallIfNotOnCooldown(COMMON_COOLDOWNS.WORLD_COMMAND, Times.clickInterval, function()
					-- If any unit is selected, move it to the clicked position, give the interactable if it is not selectable (e.g: a tree)
					CurrentPlayer:sendCommandTo(worldX, worldY, interactable)
				end)
			end
		end

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
end

function WorldMap:pushWorldSpace()
	love.graphics.push()
    love.graphics.translate(-self.camera.x * self.cameraWorldScale, -self.camera.y * self.cameraWorldScale)
	love.graphics.scale(self.cameraWorldScale, self.cameraWorldScale)
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

	-- Draw a rectangle around the current mouse tile (if there is one)
	if (love.mouse.isCursorSupported()) then
		local pointerX, pointerY = Input.GetPointerPosition()
		local worldX, worldY = self:screenToWorld(pointerX, pointerY, true)
		local screenX, screenY = self:worldToScreen(worldX, worldY)

		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle('line', screenX, screenY, GameConfig.tileSize * scaleX, GameConfig.tileSize * scaleY)
	end

    for _, faction in ipairs(self.world.factions) do
        for _, structure in ipairs(faction:getStructures()) do
            -- Check if the structure is in the camera view, if so share that with the structure
            local screenInfo = structure:isInCameraView(
                self.camera.x * self.cameraWorldScale,
                self.camera.y * self.cameraWorldScale,
                width,
				height,
            	self.cameraWorldScale)

            if (screenInfo) then
				structure:postDrawOnScreen(screenInfo.x, screenInfo.y, screenInfo.width, screenInfo.height, self.cameraWorldScale)
			end
		end
	end
end

return WorldMap
