--- Represents an interactable object in the wolr.d
--- @class Interactable
--- @field x number # The x position of the unit
--- @field y number # The y position of the unit
--- @field isSelected boolean # Whether the unit is selected
local Interactable = DeclareClass('Interactable')

--- Initializes the unit
--- @param config table
function Interactable:initialize(config)
    config = config or {}

	table.Merge(self, config)
end

--- Draws the interactable on the hud
--- @param x number
--- @param y number
--- @param width number
--- @param height number
function Interactable:drawHudIcon(x, y, width, height)
	-- Override this in the child class
end

--- Checks if the unit is in the given position
--- @param x number
--- @param y number
--- @return boolean
function Interactable:isInPosition(x, y)
	return self.x == x and self.y == y
end

--- Selects the unit
--- @param selected boolean
function Interactable:setSelected(selected)
    assert(CurrentPlayer, 'Selecting only supported for the current player.')

    self.isSelected = selected

	if (selected) then
		CurrentPlayer:addSelectedInteractable(self)
	else
		CurrentPlayer:removeSelectedInteractable(self)
	end
end

return Interactable
