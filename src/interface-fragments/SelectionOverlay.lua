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

    self.selectedInteractables = CurrentPlayer:getSelectedInteractables()

	self.selectAllButton = Button({
		text = 'Select All',
		isClippingDisabled = true,
		x = 0,
		y = 0,
		width = 64,
		height = 32,
		onClick = function()
			CurrentPlayer:selectAllInteractablesOfSameType()
		end
	})
    self.childFragments:add(self.selectAllButton)

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

	self.actionButtons = {}

    return self
end

--- Updates the fragment
--- @param deltaTime number @ The time in seconds since the last update
function SelectionOverlay:performUpdate(deltaTime)
    -- Keep track of the last unit type, if its different, refresh the unit actions.
    local firstSelectedInteractable = self.selectedInteractables[1]

    if (not firstSelectedInteractable) then
        self:refreshSelectionActions()
        return
    end

	self:refreshSelectionActions(self.selectedInteractables)
end

--- Gets a hash of the selected interactables. Appends the ids in order to create a unique, yet comparable hash.
--- @param selectedInteractables Interactable[]|nil
--- @return string
function SelectionOverlay:getHash(selectedInteractables)
	local hash = ''

	if (selectedInteractables) then
		for i, interactable in ipairs(selectedInteractables) do
			hash = hash .. interactable.id .. ','
		end
	end

	return hash:sub(1, -2)
end

--- Refreshes the unit actions
--- @param selectedInteractables Interactable[]|nil
function SelectionOverlay:refreshSelectionActions(selectedInteractables)
    if (not self.lastSelectedInteractablesHash and not selectedInteractables) then
        return
    end

    local selectedInteractablesHash = self:getHash(selectedInteractables)

	if (self.lastSelectedInteractablesHash == selectedInteractablesHash) then
		return
	end

	self.lastSelectedInteractablesHash = selectedInteractablesHash

    for i, button in ipairs(self.actionButtons) do
        button:doCleanup()
        button:destroy()
    end

    self.actionButtons = {}

	if (not selectedInteractables) then
		return
	end

    local selectionOverlay = self
	local actions = {}

    for i, interactable in ipairs(selectedInteractables) do
        local selectionType

        if (interactable:isOfType(Unit)) then
            selectionType = interactable:getUnitType()
        elseif (interactable:isOfType(Structure)) then
            selectionType = interactable:getStructureType()
        else
            print(false, 'Unknown interactable type.')
        end

        if (selectionType) then
            if (interactable.getDefaultActions) then
                table.Append(actions, interactable:getDefaultActions())
            end

            if (selectionType.getActions) then
                table.Append(actions, selectionType:getActions(interactable))
            end
        end
    end

	-- Remove any duplicate actions based on their action.id
	local uniqueActions = {}

	for i, action in ipairs(actions) do
		local isUnique = true

		for j, uniqueAction in ipairs(uniqueActions) do
			if (uniqueAction.id == action.id) then
				isUnique = false
				break
			end
		end

		if (isUnique) then
			uniqueActions[#uniqueActions + 1] = action
		end
	end

	for i, action in ipairs(uniqueActions) do
		local button = Button({
			text = action.text,
			icon = action.icon,
			isClippingDisabled = true,
			isEnabled = action.isEnabled,
			x = 0,
			y = 0,
			width = 64,
			height = 32,
			action = action,
			onClick = function(button)
				button.action:onRun(selectionOverlay)
			end
		})

		function button:doCleanup()
			if (self.action.onCleanup) then
				self.action:onCleanup(selectionOverlay)
			end
		end

		button:setPosition(0, 32 * (#self.actionButtons + 1))
		self.childFragments:add(button)
		self.actionButtons[#self.actionButtons + 1] = button
	end
end

function SelectionOverlay:performDraw(x, y)
    local interactableSize = GameConfig.tileSize * 4
    local interactablesPerRow = 3
    local totalInteractables = #self.selectedInteractables
	local shadowHeight = Sizes.padding()

	if (totalInteractables == 0) then
		self.selectAllButton:setEnabled(false)
		self.selectAllButton:setVisible(false)
		self.deselectButton:setEnabled(false)
		self.deselectButton:setVisible(false)
		return
	end

    local buttonHeights = self.selectAllButton.height + self.deselectButton.height + Sizes.padding()

	for i, button in ipairs(self.actionButtons) do
		buttonHeights = buttonHeights + button.height + Sizes.padding()
	end

    -- Calculate width and height based on the number of interactables
    local rows = math.ceil(totalInteractables / interactablesPerRow)
    local width = interactableSize * interactablesPerRow + Sizes.padding(2)
    local height = interactableSize * rows
        + shadowHeight
        + Fonts.default:getHeight()
        + Sizes.padding(2)
        + (Sizes.padding() * rows)
		+ buttonHeights

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

            -- Only increment Y if we're not on the last row
			if i < totalInteractables then
				interactableY = interactableY + Sizes.padding() + interactableSize
			end
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

	self.selectAllButton:setEnabled(true)
	self.selectAllButton:setVisible(true)
	self.selectAllButton:setSize(width, 32)
    self.selectAllButton:setPosition(
		x + width * .5 - self.selectAllButton.width * .5,
        interactableY + interactableSize + Sizes.padding()
    )
	interactableY = interactableY + self.selectAllButton.height + Sizes.padding()

	self.deselectButton:setEnabled(true)
	self.deselectButton:setVisible(true)
	self.deselectButton:setSize(width, 32)
    self.deselectButton:setPosition(
		x + width * .5 - self.deselectButton.width * .5,
        interactableY + interactableSize + Sizes.padding()
	)

    -- Draw the action buttons below the deselect button
    local actionButtonY = self.deselectButton.y + self.deselectButton.height + Sizes.padding()

    for i, button in ipairs(self.actionButtons) do
        button:setSize(width, 32)
        button:setPosition(
            x + width * .5 - self.deselectButton.width * .5,
            actionButtonY
        )
        actionButtonY = actionButtonY + button.height + Sizes.padding()
    end
end

return SelectionOverlay
