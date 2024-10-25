local UNIT = {}

UNIT.id = 'villager'
UNIT.name = 'Villager'

UNIT.imagePath = 'assets/images/tilemaps/units.png'
UNIT.idleImageOffset = {
	{
		x = 0,
		y = 0,
	  --   width = 8, -- defaults to GameConfig.tileSize
	  --   height = 8
	}
}

UNIT.actionImageOffset = {
	-- The positions of the 3 animation frames for the unit
	{
		x = 0,
		y = 8,
	},
	{
		x = 8,
		y = 8,
	},
	{
		x = 16,
		y = 8,
	},
	{
		x = 8,
		y = 8,
	},
}

--- Called after the unit is drawn on screen
--- @param unit Unit
--- @param minX number
--- @param minY number
--- @param maxX number
--- @param maxY number
function UNIT:postDrawOnScreen(unit, minX, minY, maxX, maxY)
end

-- --- @param unit Unit
-- function UNIT:onSpawn(unit)
-- end

--- Gets the actions that the unit can perform
--- Should always return the same actions, but the actions may be disabled or with different progress
--- @param selectedInteractable Interactable
--- @return table
function UNIT:getActions(selectedInteractable)
    local ACTION_BUILD = {}
    ACTION_BUILD.text = 'Build'
    ACTION_BUILD.icon = 'assets/images/icons/build.png'

    function ACTION_BUILD:onRun(selectionOverlay)
		if (not self.buildMenu) then
			self.buildMenu = BuildMenu({
				isVisible = false
            })
			selectionOverlay.childFragments:add(self.buildMenu)
		end

		self.buildMenu:setVisible(not self.buildMenu.isVisible)
	end

	-- Called when the action menu is closed
    function ACTION_BUILD:onCleanup(selectionOverlay)
		if (self.buildMenu) then
			self.buildMenu:destroy()
		end
	end

    return {
		ACTION_BUILD
	}
end

return UNIT
