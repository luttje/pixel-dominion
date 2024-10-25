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

	self.holdTimer = 0
	self.heldInteractable = nil
	self.isHolding = false

	-- This is used so holding on a interactable doesn't keep toggling the selection
	self.hasReleasedSinceLastSelection = true

	self:centerOnTownHall()

	self.placeStructureButton = Button({
		text = 'Place',
		x = 0,
		y = 0,
		width = 100,
		height = 50,
		-- isVisible = false,
		onClick = function()
			local structureToBuild, builders, position = CurrentPlayer:getCurrentStructureToBuild()

			if (not position) then
				print('TODO: Error sound')
				return
			end

			assert(builders[1], 'No builders to build the structure')
			local faction = builders[1]:getFaction()

			if (not structureToBuild:canBeBuilt(faction)) then
				print('TODO: Error sound')
				return
			end

			-- TODO: Have the builders build the structure
			print('TODO: success sound')

			structureToBuild:subtractResources(faction)
			CurrentPlayer:getFaction():spawnStructure(structureToBuild, position.x, position.y, builders)
			CurrentPlayer:clearCurrentStructureToBuild()
		end
	})
	self.childFragments:add(self.placeStructureButton)

	self.cancelStructureButton = Button({
		text = 'Cancel',
		x = 0,
		y = 0,
		width = 100,
		height = 50,
		-- isVisible = false,
		onClick = function()
			CurrentPlayer:clearCurrentStructureToBuild()
		end
	})
	self.childFragments:add(self.cancelStructureButton)
end

--- Centers the camera on the current player's faction's town hall
function WorldMap:centerOnTownHall()
	local townHall = CurrentPlayer:getFaction():getTownHall()

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

	if (CurrentPlayer:getWorldInputBlocker()) then
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
		else
			local worldX, worldY = self:screenToWorld(pointerX, pointerY, true)
			local interactable = self.world:getInteractableUnderPosition(worldX, worldY)

			if (love.mouse.isDown(1)) then
				-- Start or update hold timer logic
				if (
						not self.isHolding
						and self.hasReleasedSinceLastSelection
						and interactable
						and interactable.isSelectable
						and interactable:getFaction() == CurrentPlayer:getFaction()
					) then
					-- Initialize hold
					self.isHolding = true
					self.holdTimer = 0
					self.heldInteractable = interactable
					self.hasReleasedSinceLastSelection = false
				elseif (self.isHolding) then
					-- Check if we're still hovering over the same interactable
					if (interactable == self.heldInteractable) then
						-- Update hold timer
						self.holdTimer = self.holdTimer + deltaTime

						-- Check if we've held long enough
						if (self.holdTimer >= GameConfig.selectHoldTimeInSeconds) then
							if (CurrentPlayer:isSameTypeAsSelected(self.heldInteractable)) then
								-- If the unit is selected, deselect it
								if (self.heldInteractable.isSelected) then
									self.heldInteractable:setSelected(false)
								else
									-- If the unit is not selected, select it
									self.heldInteractable:setSelected(true)
								end
							else
								-- If the unit is not the same type, deselect all units and select this one
								CurrentPlayer:clearSelectedInteractables()
								self.heldInteractable:setSelected(not self.heldInteractable.isSelected)
							end

							-- Reset hold state after selection
							self.isHolding = false
							self.holdTimer = 0
							self.heldInteractable = nil
						end
					else
						-- Reset hold if we're no longer over the same interactable
						self.isHolding = false
						self.holdTimer = 0
						self.heldInteractable = nil
					end
				end

				-- Handle regular clicks for movement commands
				if (not self.isHolding and self.hasReleasedSinceLastSelection) then
					-- If any unit is selected, move it to the clicked position
					CurrentPlayer:sendCommandTo(worldX, worldY, interactable)
					self.hasReleasedSinceLastSelection = false
				end
			else
				-- Handle mouse release before holding completes for interaction commands
				if (self.isHolding and interactable and self.heldInteractable == interactable) then
					CurrentPlayer:sendCommandTo(worldX, worldY, interactable)
				end

				-- Reset hold state when mouse button is released
				self.isHolding = false
				self.holdTimer = 0
				self.heldInteractable = nil
				self.hasReleasedSinceLastSelection = true
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

	local function drawPostScreen(interactable)
		-- Check if the interactable is in the camera view, if so share that with the interactable
		local screenInfo = interactable:isInCameraView(
			self.camera.x * self.cameraWorldScale,
			self.camera.y * self.cameraWorldScale,
			width,
			height,
			self.cameraWorldScale)

		if (screenInfo) then
			interactable:postDrawOnScreen(screenInfo.x, screenInfo.y, screenInfo.width, screenInfo.height,
				self.cameraWorldScale)
		end
	end

	for _, faction in ipairs(self.world.factions) do
		for _, interactable in ipairs(faction:getInteractables()) do
			drawPostScreen(interactable)
		end
	end

	for _, interactable in ipairs(self.world:getResourceInstances()) do
		drawPostScreen(interactable)
	end

	-- If we're building a structure, draw a ghost of it
	local structureToBuild, builders = CurrentPlayer:getCurrentStructureToBuild()

	if (structureToBuild) then
		local buildScreenX, buildScreenY = width * .5, height * .5
		local worldX, worldY = self:screenToWorld(buildScreenX, buildScreenY, true)
		local screenX, screenY = self:worldToScreen(worldX, worldY)

		-- Check if the structure can be placed at the current location
		local canPlace = structureToBuild:canPlaceAt(worldX, worldY)

		CurrentPlayer:setCurrentStructureBuildPosition(worldX, worldY, canPlace)

		-- Draw the structure
		structureToBuild:drawGhost(screenX, screenY, self.cameraWorldScale, canPlace)

		-- Draw a hint above the ghost
		local hint = 'Drag around to choose a location'
		local hintHeight = Fonts.defaultHud:getHeight()
		love.graphics.setColor(0, 0, 0, 0.5)
		love.graphics.printf(hint, width * .1,
			screenY - hintHeight - Sizes.padding() - (GameConfig.tileSize * self.cameraWorldScale), width * .8, 'center')

		-- Show the place and cancel buttons below the ghost
		self.placeStructureButton.x = love.graphics.getWidth() * .5 - (self.placeStructureButton.width * .5)
		self.placeStructureButton.y = screenY + Sizes.padding() + GameConfig.tileSize * self.cameraWorldScale
		self.placeStructureButton:setEnabled(canPlace)
		self.placeStructureButton:setVisible(true)

		self.cancelStructureButton.x = self.placeStructureButton.x
		self.cancelStructureButton.y = self.placeStructureButton.y + self.placeStructureButton.height + Sizes.padding()
		self.cancelStructureButton:setEnabled(true)
		self.cancelStructureButton:setVisible(true)
	else
		self.placeStructureButton:setVisible(false)
		self.placeStructureButton:setEnabled(false)
		self.cancelStructureButton:setVisible(false)
		self.cancelStructureButton:setEnabled(false)
	end
end

return WorldMap
