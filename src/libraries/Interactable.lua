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

return Interactable
