local RESOURCE = {}

RESOURCE.id = 'gold'
RESOURCE.name = 'Gold'
RESOURCE.orderWeight = 4

RESOURCE.imagePath = 'assets/images/resources/gold.png'

local sounds = {
	Sounds.stoneMining2,
	Sounds.stoneMining3,
	Sounds.stoneMining4,
}

RESOURCE.spawnAtTileId = 28
RESOURCE.harvestableTilesetInfo = {
	-- Ore 1
	{
		harvestSounds = sounds,
		tiles = {
			{
				tilesetId = 1,
				tileId = 404,
				targetLayer = 'Dynamic_Bottom',
			},
		},
	},
	-- Ore 2
    {
		harvestSounds = sounds,
		tiles = {
			{
				tilesetId = 1,
				tileId = 405,
				targetLayer = 'Dynamic_Bottom',
			},
		},
	},
}

return RESOURCE
