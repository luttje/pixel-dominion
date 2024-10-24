local RESOURCE = {}

RESOURCE.id = 'gold'
RESOURCE.name = 'Gold'
RESOURCE.orderWeight = 4

RESOURCE.imagePath = 'assets/images/resources/gold.png'

RESOURCE.spawnAtTileId = 28
RESOURCE.harvestableTilesetInfo = {
	-- Ore 1
	{
		{
			tilesetId = 1,
			tileId = 404,
			targetLayer = 'Dynamic_Bottom',
		},
	},
	-- Ore 2
	{
		{
			tilesetId = 1,
			tileId = 405,
			targetLayer = 'Dynamic_Bottom',
		},
	},
}

return RESOURCE
