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

--- Returns the default actions for the selection overlay, such
--- as selecting all units of the same type, deselecting all units, etc.
--- @return table[]
function SelectionOverlay:getDefaultActions()
	local actions = {}

	actions[#actions + 1] = {
		id = 'select_all',
		text = 'Select All',
		icon = 'select_all',
		isEnabled = true,
		onRun = function(self)
			CurrentPlayer:selectAllInteractablesOfSameType()
		end
	}

	actions[#actions + 1] = {
		id = 'deselect_all',
		text = 'Deselect All',
		icon = 'deselect_all',
		isEnabled = true,
		onRun = function(self)
			CurrentPlayer:clearSelectedInteractables()
		end
	}

	return actions
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

	table.Append(actions, self:getDefaultActions())

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
            if (interactable.getActions) then
                table.Append(actions, interactable:getActions())
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
		local resourceInventory
        local buttonType = Button

		if (action.costs) then
			resourceInventory = ResourceInventory()
			buttonType = ResourceButton

			-- Append required resources
			for resourceTypeId, amount in pairs(action.costs) do
				resourceInventory:add(resourceTypeId, amount)
			end
		end

		local button = buttonType({
			text = action.text,
			icon = action.icon,
			isClippingDisabled = true,
			isEnabled = action.isEnabled,
			x = 0,
			y = 0,
			width = 64, -- Set later
			height = 64,
			action = action,
			resourceInventory = resourceInventory,
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
	local zoom = 6
    local interactableSize = GameConfig.tileSize * zoom
    local interactablesPerRow = 3
    local totalInteractables = #self.selectedInteractables
	local shadowHeight = Sizes.padding()

	if (totalInteractables == 0) then
		return
	end

    local buttonHeights = Sizes.padding()

	for i, button in ipairs(self.actionButtons) do
		buttonHeights = buttonHeights + button.height + Sizes.padding()
	end

    -- Calculate width and height based on the number of interactables
    local rows = math.ceil(totalInteractables / interactablesPerRow)
    local width = interactableSize * interactablesPerRow + Sizes.padding(2)
    local height = interactableSize * rows
        + shadowHeight
        + Fonts.default:getHeight()
        + (Sizes.padding() * rows)
        + buttonHeights

    -- Center us vertically
	y = y - (height * .5)

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

    -- Draw the action buttons below the deselect button
    local actionButtonY = interactableY + interactableSize + Sizes.padding()

    for i, button in ipairs(self.actionButtons) do
        button:setWidth(width)
        button:setPosition(
            x,
            actionButtonY
        )
        actionButtonY = actionButtonY + button.height + Sizes.padding()
    end
end

return SelectionOverlay
