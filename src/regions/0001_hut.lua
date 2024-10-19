-- Enough space to go in all directions
local originX, originY = 5000, 6000
local areaWidth, areaHeight = 10, 10
local backgroundBuffer = 1

local worldData = {
    homePosition = {
        x = originX + (areaHeight * .5),
		y = originY + (areaWidth * .5),
    },
    x = originX,
	y = originY,
    width = areaWidth,
    height = areaHeight,

	layers = {
		{
			-- Background tiles, only grass now
            name = 'Background',
			withoutShadows = true,
			tiles = {
				{
					x = originX - backgroundBuffer,
					y = originY - backgroundBuffer,
					untilX = originX + areaWidth - 1 + backgroundBuffer,
					untilY = originY + areaHeight - 1 + backgroundBuffer,
					imageSize = '100%', -- imageSize is width and height
					-- tileWidth = 128,
					-- tileHeight = 128,
					color = { 96, 140, 101 },
					imagePath = 'assets/images/world/ground/grass01.png'
				},
			},
		},

		-- {
		-- 	-- Hut and other objects
		-- 	name = 'Objects',
		-- 	tiles = {
		-- 		{
		-- 			x = originX + (areaHeight * .5),
		-- 			y = originY + (areaWidth * .5),
        --             imagePath = 'assets/images/world/tiles/hut.png',

		-- 			-- Percentage relative to tile size
		-- 			imageSize = '200%', -- imageSize is width and height
		-- 			-- imageWidth = '200%',
        --             -- imageHeight = '200%'

		-- 			hasOffScreenIndicator = true,
		-- 		},
		-- 	},
		-- },

		{
			-- Trees that obscure the view of objects
			name = 'Foliage',
			tiles = {
				{
					x = originX + 2,
					y = originY + 2,
					imagePath = 'assets/images/world/trees/tree01.png'
				},
				{
					x = originX + 2,
					y = originY + 4,
					imagePath = 'assets/images/world/trees/tree01.png'
				},
				{
					x = originX + 1,
					y = originY + 8,
					imagePath = 'assets/images/world/trees/tree01.png'
				},
				{
					x = originX + 1,
					y = originY + 5,
					imagePath = 'assets/images/world/trees/tree01.png'
				},
				{
					x = originX + 9,
					y = originY + 1,
					imagePath = 'assets/images/world/trees/tree01.png'
				},
				{
					x = originX + 7,
					y = originY + 2,
					imagePath = 'assets/images/world/trees/tree01.png'
				},
				{
					x = originX + 6,
					y = originY + 8,
					imagePath = 'assets/images/world/trees/tree01.png'
				},
			},
		}
	}
}

return Region({
	name = 'Your forsaken hut',
	description = "You have been banished to this forsaken hut. You may not be able to leave, but your hexes can. Unleash them to gain power.",
	worldData = worldData,
})
