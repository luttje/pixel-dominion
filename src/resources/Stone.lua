local RESOURCE = {}

RESOURCE.id = 'stone'
RESOURCE.name = 'Stone'
RESOURCE.orderWeight = 3
RESOURCE.defaultValue = 5

RESOURCE.imagePath = 'assets/images/resources/stone.png'

local sounds = {
	Sounds.stoneMining2,
	Sounds.stoneMining3,
	Sounds.stoneMining4,
}

RESOURCE.spawnAtTileId = 27
RESOURCE.harvestableTilesetInfo = {
	-- Stone 1
    {
		harvestSounds = sounds,
		tiles = {
			{
				tilesetId = 1,
				tileId = 400,
				targetLayer = 'Dynamic_Bottom',
			},
		},
	},
	-- Stone 2
	{
		harvestSounds = sounds,
		tiles = {
			{
				tilesetId = 1,
				tileId = 401,
				targetLayer = 'Dynamic_Bottom',
			},
		},
	},
	-- Stone 3
	{
		harvestSounds = sounds,
		tiles = {
			{
				tilesetId = 1,
				tileId = 402,
				targetLayer = 'Dynamic_Bottom',
			},
		},
	},
	-- Stone 4
	{
		harvestSounds = sounds,
		tiles = {
			{
				tilesetId = 1,
				tileId = 403,
				targetLayer = 'Dynamic_Bottom',
			},
		},
	},
}

return RESOURCE
