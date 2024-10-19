local originX, originY = 4995, 5990
local areaWidth, areaHeight = 10, 10
local backgroundBuffer = 1

local worldData = {
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

		{
			-- Hut and other objects
			name = 'Objects',
			tiles = {

			},
		},

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
	name = 'Reign the forest',
	worldData = worldData,
})
