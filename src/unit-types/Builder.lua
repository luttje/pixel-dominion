local UNIT = {}

UNIT.id = 'builder'
UNIT.name = 'Builder'

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

return UNIT
