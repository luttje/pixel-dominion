local ImageCache = {}

-- We store already loaded images here for performance
local loadedImages = {}

function ImageCache:get(imagePath)
	if (loadedImages[imagePath]) then
		return loadedImages[imagePath]
	end

	local image = love.graphics.newImage(imagePath)
	loadedImages[imagePath] = image

	return image
end

return ImageCache
