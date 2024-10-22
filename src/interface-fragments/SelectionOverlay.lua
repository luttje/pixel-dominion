--- Shows all currently selected interactables of the player
--- @class SelectionOverlay: InterfaceFragment
local SelectionOverlay = DeclareClassWithBase('SelectionOverlay', InterfaceFragment)

function SelectionOverlay:initialize(config)
    assert(CurrentPlayer, 'Player is required.')

	-- We calculate this based on the content
	config.isClippingDisabled = true
    config.width = 0
	config.height = 0

    table.Merge(self, config)

    self:refreshSelection()

	self.deselectButton = Button({
		text = 'Deselect',
		isClippingDisabled = true,
		x = 0,
		y = 0,
		width = 64,
		height = 32,
		onClick = function()
			CurrentPlayer:clearSelectedInteractables()
		end
	})

	self.childFragments:add(self.deselectButton)

    return self
end

function SelectionOverlay:refreshSelection()
    self.selectedInteractables = CurrentPlayer:getSelectedInteractables()
end

function SelectionOverlay:performDraw(x, y)
    local interactableSize = GameConfig.tileSize * 4
    local interactablesPerRow = 3
    local totalInteractables = #self.selectedInteractables
	local shadowHeight = Sizes.padding()


	if (totalInteractables == 0) then
		self.deselectButton:setVisible(false)
		return
	end

    -- Calculate width and height based on the number of interactables
    local rows = math.ceil(totalInteractables / interactablesPerRow)
    local width = interactableSize * interactablesPerRow + Sizes.padding(2)
    local height = interactableSize * rows + shadowHeight + Fonts.default:getHeight() + Sizes.padding(2) + (Sizes.padding() * (#self.selectedInteractables / interactablesPerRow)) + self.deselectButton.height

    -- Offset x so its right aligned
	x = x - width - Sizes.padding()

    -- Draw background and shadow
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.rectangle('fill', x, y, width, height)
    love.graphics.setColor(0.2, 0.5, 0.5, 0.5)
    love.graphics.rectangle('fill', x, y, width, height - shadowHeight)

    -- Add a 'Selected:' label on top
    love.graphics.setFont(Fonts.defaultHud)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print('Selected:', x + 4, y)

    local interactableX = x + Sizes.padding()
    local interactableY = y + Fonts.defaultHud:getHeight() + Sizes.padding()

    -- Loop through and draw each interactable
    for i, interactable in ipairs(self.selectedInteractables) do
        interactable:drawHudIcon(interactableX, interactableY, interactableSize, interactableSize)

        -- Increment position
        interactableX = interactableX + interactableSize
        if i % interactablesPerRow == 0 then
            interactableX = x + Sizes.padding()
            interactableY = interactableY + Sizes.padding() + interactableSize
        end

        -- If the unit is selected, draw a selection marker above it in the world
        local worldX, worldY = interactable:getWorldPosition()
        worldX = worldX * GameConfig.tileSize
        worldY = worldY * GameConfig.tileSize

		if (interactable.getDrawOffset) then
			local offsetX, offsetY = interactable:getDrawOffset()
			worldX = worldX + offsetX
			worldY = worldY + offsetY
		end

        love.graphics.setColor(Colors.selectedMarker())
		local arrowSize = GameConfig.tileSize * .3

		self.worldMap:drawInWorldSpace(function()
			-- arrow-like shape
			love.graphics.polygon(
                'fill',
                worldX + GameConfig.tileSize * .5, worldY - arrowSize,
                worldX + GameConfig.tileSize * .5 - arrowSize, worldY - arrowSize * 2,
                worldX + GameConfig.tileSize * .5 + arrowSize, worldY - arrowSize * 2
			)
		end)
    end

	self.deselectButton:setVisible(true)
	self.deselectButton:setSize(width, 32)
	self.deselectButton:setPosition(x + width * .5 - self.deselectButton.width * .5, y + height - self.deselectButton.height - shadowHeight)
end

return SelectionOverlay
