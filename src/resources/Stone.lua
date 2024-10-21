local RESOURCE = {}

RESOURCE.id = 'stone'
RESOURCE.name = 'Stone'
RESOURCE.orderWeight = 3

RESOURCE.imagePath = 'assets/images/resources/stone.png'

RESOURCE.spawnAtTileId = 27
RESOURCE.worldTilesetInfo = {
	-- Stone 1
	{
		{
			tilesetId = 1,
			tileId = 400,
			targetLayer = 'Dynamic_Bottom',
		},
	},
	-- Stone 2
	{
		{
			tilesetId = 1,
			tileId = 401,
			targetLayer = 'Dynamic_Bottom',
		},
	},
	-- Stone 3
	{
		{
			tilesetId = 1,
			tileId = 402,
			targetLayer = 'Dynamic_Bottom',
		},
	},
	-- Stone 4
	{
		{
			tilesetId = 1,
			tileId = 403,
			targetLayer = 'Dynamic_Bottom',
		},
	},
}

return RESOURCE
