local STRUCTURE = {}

STRUCTURE.id = "town_hall"
STRUCTURE.name = "Town Hall"

STRUCTURE.imagePath = "assets/images/structures/town-hall.png"

STRUCTURE.worldTilesetInfo = {
	-- Town Hall 1
	{
		-- Top of the town hall
		{
			tilesetId = 2,
			tileId = 517,
			targetLayer = 'Dynamic_Top',
			offsetX = 0,
			offsetY = -1,
		},
		{
			tilesetId = 2,
			tileId = 518,
			targetLayer = 'Dynamic_Top',
			offsetX = 1,
			offsetY = -1,
		},
		{
			tilesetId = 2,
			tileId = 519,
			targetLayer = 'Dynamic_Top',
			offsetX = 2,
			offsetY = -1,
		},
		-- Bottom of the town hall
		{
			tilesetId = 2,
			tileId = 617,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 0,
			offsetY = 0,
		},
		{
			tilesetId = 2,
			tileId = 618,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 1,
			offsetY = 0,
        },
		{
			tilesetId = 2,
			tileId = 619,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 2,
			offsetY = 0,
		},
    },
}

return STRUCTURE
