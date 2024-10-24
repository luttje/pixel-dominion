local RESOURCE = {}

RESOURCE.id = 'wood'
RESOURCE.name = 'Wood'
RESOURCE.orderWeight = 2

RESOURCE.imagePath = 'assets/images/resources/wood.png'

local sounds = {
	Sounds.treeRustling1,
	Sounds.treeRustling2,
	Sounds.treeRustling3,
	Sounds.treeRustling4,
}

RESOURCE.spawnAtTileId = 26 -- 0-based Tile ID for tree spawn
RESOURCE.harvestableTilesetInfo = {
	-- Tree 1
    {
		harvestSounds = sounds,
		tiles = {
			-- Top of the tree
			{
				tilesetId = 1,
				tileId = 210,
				targetLayer = 'Dynamic_Top',
				offsetX = 0,
				offsetY = -1,
			},
			{
				tilesetId = 1,
				tileId = 211,
				targetLayer = 'Dynamic_Top',
				offsetX = 1,
				offsetY = -1,
			},
			-- Bottom of the tree
			{
				tilesetId = 1,
				tileId = 310,
				targetLayer = 'Dynamic_Bottom',
				offsetX = 0,
				offsetY = 0,
			},
			{
				tilesetId = 1,
				tileId = 311,
				targetLayer = 'Dynamic_Bottom',
				offsetX = 1,
				offsetY = 0,
			},
		}
    },

	-- Tree 2 is below it in the spritesheet
	{
		harvestSounds = sounds,
		tiles = {
			-- Top of the tree
			{
				tilesetId = 1,
				tileId = 410,
				targetLayer = 'Dynamic_Top',
				offsetX = 0,
				offsetY = -1,
			},
			{
				tilesetId = 1,
				tileId = 411,
				targetLayer = 'Dynamic_Top',
				offsetX = 1,
				offsetY = -1,
			},
			-- Bottom of the tree
			{
				tilesetId = 1,
				tileId = 510,
				targetLayer = 'Dynamic_Bottom',
				offsetX = 0,
				offsetY = 0,
			},
			{
				tilesetId = 1,
				tileId = 511,
				targetLayer = 'Dynamic_Bottom',
				offsetX = 1,
				offsetY = 0,
			},
		},
	},
}

return RESOURCE
