local Resources = {}

function Resources:registerResources()
	ResourceTypeRegistry:registerResourceType('food', {
        name = 'Food',
		imagePath = 'assets/images/resources/food.png'
	})

	ResourceTypeRegistry:registerResourceType('wood', {
        name = 'Wood',
        imagePath = 'assets/images/resources/wood.png',
        spawnAtTileId = 26, -- 0-based Tile ID for tree spawn
        worldTilesetInfo = {
			-- Tree 1
            {
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
            },
            -- Tree 2 is below it in the spritesheet
			{
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
	})

	ResourceTypeRegistry:registerResourceType('stone', {
        name = 'Stone',
		imagePath = 'assets/images/resources/stone.png',
        spawnAtTileId = 27,
		worldTilesetInfo = {
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
		},
	})

	ResourceTypeRegistry:registerResourceType('gold', {
        name = 'Gold',
		imagePath = 'assets/images/resources/gold.png'
	})

	ResourceTypeRegistry:registerResourceType('housing', {
        name = 'Housing',
        imagePath = 'assets/images/resources/housing.png',
		defaultValue = 5,
		formatValue = function(value)
            local units = CurrentPlayer:getFaction():getUnits()

			return ('%d/%d'):format(#units, value)
		end
	})
end

return Resources
