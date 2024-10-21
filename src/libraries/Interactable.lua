--- Represents an interactable object in the wolr.d
--- @class Interactable
--- @field x number # The x position of the interactable
--- @field y number # The y position of the interactable
--- @field isSelected boolean # Whether the interactable is selected
--- @field isSelectable boolean # Whether the interactable is selectable
local Interactable = DeclareClass('Interactable')

--- Initializes the interactable
--- @param config table
function Interactable:initialize(config)
    config = config or {}

	self.isSelectable = true

	table.Merge(self, config)
end

--- When an interactable is interacted with
--- @param interactable Interactable
function Interactable:interact(interactable)
	-- Override this in the child class
end

--- Draws the interactable on the hud
--- @param x number
--- @param y number
--- @param width number
--- @param height number
function Interactable:drawHudIcon(x, y, width, height)
	-- Override this in the child class
end

--- Gets the world position of the interactable
--- @return number, number
function Interactable:getWorldPosition()
	return self.x, self.y
end

--- Checks if the interactable is in the given position
--- @param x number
--- @param y number
--- @return boolean
function Interactable:isInPosition(x, y)
	return self.x == x and self.y == y
end

--- Selects the interactable
--- @param selected boolean
function Interactable:setSelected(selected)
    if (not self.isSelectable) then
        return
    end

    assert(CurrentPlayer, 'Selecting only supported for the current player.')

    self.isSelected = selected

	if (selected) then
		CurrentPlayer:addSelectedInteractable(self)
	else
		CurrentPlayer:removeSelectedInteractable(self)
	end
end

--- Gets if the interactable is selected
--- @return boolean
function Interactable:getIsSelected()
	return self.isSelected
end

--- Finds a free tile nearby the Interactable
--- @param interactables? Interactable[]
--- @param nearX? number
--- @param nearY? number
--- @return number?, number?
function Interactable:getFreeTileNearby(interactables, nearX, nearY)
	nearX, nearY = nearX or self.x, nearY or self.y

    -- Look further and further away until we find a free tile is found.
	for range = 1, math.huge do
		for _, offset in pairs(GameConfig.unitPathingOffsets) do
			local newX, newY = nearX + (offset.x * range), nearY + (offset.y * range)

			-- Also check if any interactables are in the way
			local isInteractableInWay = false

			if (interactables) then
				for _, interactable in pairs(interactables) do
					if (interactable:isInPosition(newX, newY)) then
						isInteractableInWay = true
						break
					end
				end
			end

			if (not isInteractableInWay and not CurrentWorld:isTileOccupied(newX, newY)) then
				return newX, newY
			end
		end

        if (range > 100) then
			-- Prevent infinite loop
			break
		end
	end

	return nil, nil
end

return Interactable
