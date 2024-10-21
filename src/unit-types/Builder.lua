local UNIT_TYPE = {}

UNIT_TYPE.id = "builder"
UNIT_TYPE.name = "Builder"

UNIT_TYPE.imagePath = "assets/images/tilemaps/units.png"
UNIT_TYPE.idleImageOffset = {
	{
		x = 0,
		y = 0,
	  --   width = 8, -- defaults to GameConfig.tileSize
	  --   height = 8
	}
}

UNIT_TYPE.actionImageOffset = {
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

return UNIT_TYPE
