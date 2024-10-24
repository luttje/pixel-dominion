local UNIT = {}

UNIT.id = 'warrior'
UNIT.name = 'Warrior'

UNIT.imagePath = 'assets/images/tilemaps/units.png'
UNIT.idleImageOffset = {
	{
		x = 96,
		y = 0,
	}
}

UNIT.actionImageOffset = {
	{
		x = 96,
		y = 0,
	}
}

--- Called after the unit is drawn on screen
--- @param unit Unit
--- @param minX number
--- @param minY number
--- @param maxX number
--- @param maxY number
function UNIT:postDrawOnScreen(unit, minX, minY, maxX, maxY)
end

--- Gets the actions that the unit can perform
--- Should always return the same actions, but the actions may be disabled or with different progress
--- @param selectedInteractable Interactable
--- @return table
function UNIT:getActions(selectedInteractable)
    local ACTION_STOP_ATTACK = {}
    ACTION_STOP_ATTACK.text = 'Stop Attacking'
    ACTION_STOP_ATTACK.icon = 'assets/images/icons/attack.png'
    ACTION_STOP_ATTACK.isEnabled = false

    function ACTION_STOP_ATTACK:onRun(selectionOverlay)
		print('Stop attacking')
	end

    return {
		ACTION_STOP_ATTACK
	}
end

return UNIT
