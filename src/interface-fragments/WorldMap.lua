--- Represents the world map the player can interact with
--- @class WorldMap: InterfaceFragment
local WorldMap = DeclareClassWithBase('WorldMap', InterfaceFragment)

function WorldMap:initialize(config)
	assert(self.world, 'World is required.')

	table.Merge(self, config)

	self.camera = { x = 0, y = 0 }
	self.dragging = false
	self.dragStart = { x = 0, y = 0 }

	self.clickThroughToWorld = true
	self.finishHoldAt = nil
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

			-- TODO: Have the builders build the structure instead of just spawning it
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

--- Returns the scale of the world map camera
--- @return number
function WorldMap:getCameraWorldScale()
	return GameConfig.worldMapCameraScale
end

--- Centers the camera on the current player's faction's town hall
function WorldMap:centerOnTownHall()
	local townHall = CurrentPlayer:getFaction():getTownHall()

	self.camera.x = (townHall.x * GameConfig.tileSize) - (self:getWidth() * .5) / self:getCameraWorldScale()
	self.camera.y = (townHall.y * GameConfig.tileSize) - (self:getHeight() * .4) / self:getCameraWorldScale()
end

function WorldMap:screenToWorld(x, y, snapToTile)
	if (snapToTile) then
		return math.floor((x + self.camera.x * self:getCameraWorldScale()) / (GameConfig.tileSize * self:getCameraWorldScale())),
			math.floor((y + self.camera.y * self:getCameraWorldScale()) / (GameConfig.tileSize * self:getCameraWorldScale()))
	end

	return (x + self.camera.x * self:getCameraWorldScale()) / (GameConfig.tileSize * self:getCameraWorldScale()),
		(y + self.camera.y * self:getCameraWorldScale()) / (GameConfig.tileSize * self:getCameraWorldScale())
end

function WorldMap:worldToScreen(x, y)
	return x * GameConfig.tileSize * self:getCameraWorldScale() - self.camera.x * self:getCameraWorldScale(),
		y * GameConfig.tileSize * self:getCameraWorldScale() - self.camera.y * self:getCameraWorldScale()
end

--- @param deltaTime number
--- @param isPointerWithin boolean
function WorldMap:performUpdate(deltaTime, isPointerWithin)
	local pointerX, pointerY = Input.GetPointerPosition()

	self.world:update(deltaTime)

	if (not self.dragging and CurrentPlayer:getWorldInputBlocker()) then
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

            -- If we haven't discovered the tile yet, don't allow interaction
			if (interactable and not self.world:isInteractableDiscoveredForFaction(CurrentPlayer:getFaction(), interactable)) then
				interactable = nil
			end

			if (love.mouse.isDown(1)) then
				if (
						not self.isHolding
						and self.hasReleasedSinceLastSelection
					) then
					-- Initialize hold for interacting/moving
					self.isHolding = true
					self.finishHoldAt = love.timer.getTime() + GameConfig.interactHoldTimeInSeconds
					self.heldInteractable = interactable -- can be nil
					self.hasReleasedSinceLastSelection = true
				elseif (self.isHolding) then
                    -- Check if we've held long enough on an the same interactable, if so interact with it
					-- Will also work for moving units, because nil (interactable) == nil (self.heldInteractable)
					if (interactable == self.heldInteractable) then
                        if (self.finishHoldAt <= love.timer.getTime()) then
                            if (self.hasReleasedSinceLastSelection) then
                                -- If any unit is selected, move it to the clicked position and/or interact with it
                                CurrentPlayer:sendCommandTo(worldX, worldY, interactable)
                                self.hasReleasedSinceLastSelection = false
                            end

							-- Reset hold state after selection
							self.isHolding = false
							self.finishHoldAt = nil
							self.heldInteractable = nil
						end
                    else
						-- Reset hold if we're no longer over the same interactable
						self.isHolding = false
						self.finishHoldAt = nil
						self.heldInteractable = nil
					end
				end
			else
				if (self.isHolding) then
					if (interactable and self.heldInteractable == interactable and interactable:getFaction() == CurrentPlayer:getFaction()) then
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
                    else
						-- If we didn't click anything, just move the selected units here
						if (self.hasReleasedSinceLastSelection) then
							-- If any unit is selected, move it to the clicked position and/or interact with it
							CurrentPlayer:sendCommandTo(worldX, worldY, interactable)
							self.hasReleasedSinceLastSelection = false
						end
					end
				end

				-- Reset hold state when mouse button is released
				self.isHolding = false
				self.finishHoldAt = nil
				self.heldInteractable = nil
				self.hasReleasedSinceLastSelection = true
			end
		end

		return
	elseif (not self.dragging) then
		self.dragging = true
		self.dragStart.x = pointerX + self.camera.x * self:getCameraWorldScale()
		self.dragStart.y = pointerY + self.camera.y * self:getCameraWorldScale()
	end

	if (self.dragging) then
		local newX = (self.dragStart.x - pointerX) / self:getCameraWorldScale()
		local newY = (self.dragStart.y - pointerY) / self:getCameraWorldScale()
		self.camera.x = newX
		self.camera.y = newY
	end
end

function WorldMap:pushWorldSpace()
	love.graphics.push()
	love.graphics.translate(-self.camera.x * self:getCameraWorldScale(), -self.camera.y * self:getCameraWorldScale())
	love.graphics.scale(self:getCameraWorldScale(), self:getCameraWorldScale())
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
	scaleX = self:getCameraWorldScale()
	scaleY = self:getCameraWorldScale()

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
			self.camera.x * self:getCameraWorldScale(),
			self.camera.y * self:getCameraWorldScale(),
			width,
			height,
			self:getCameraWorldScale())

		if (screenInfo) then
			interactable:postDrawOnScreen(screenInfo.x, screenInfo.y, screenInfo.width, screenInfo.height,
				self:getCameraWorldScale())
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
		local canPlace = structureToBuild:canPlaceAt(self.world, worldX, worldY)

		CurrentPlayer:setCurrentStructureBuildPosition(worldX, worldY, canPlace)

		-- Draw the structure
		structureToBuild:drawGhost(screenX, screenY, self:getCameraWorldScale(), canPlace)

		-- Draw a hint above the ghost
		local hint = 'Drag around to choose a location'
		local hintHeight = Fonts.defaultHud:getHeight()
		love.graphics.setColor(0, 0, 0, 0.5)
		love.graphics.printf(hint, width * .1,
			screenY - hintHeight - Sizes.padding() - (GameConfig.tileSize * self:getCameraWorldScale()), width * .8, 'center')

		-- Show the place and cancel buttons below the ghost
		self.placeStructureButton.x = love.graphics.getWidth() * .5 - (self.placeStructureButton.width * .5)
		self.placeStructureButton.y = screenY + Sizes.padding() + GameConfig.tileSize * self:getCameraWorldScale()
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
