--- Represents an image on the interface.
--- @class Image: InterfaceFragment
---
--- @field wrapToContents boolean If true, the button will wrap to the size of the text and icon when created.
--- @field imagePath string
---
local Image = DeclareClassWithBase('Image', InterfaceFragment)

--- Creates a new Image.
--- @param config any
function Image:initialize(config)
	table.Merge(self, config)

	assert(self.imagePath, 'Image path is required.')

	self:refreshImage()

	-- If no width or height is provided, calculate it based on the text and possible icon
	if (self.wrapToContents) then
		local iconWidth = 0
		if (self.image) then
			iconWidth = self.image:getWidth()
		end

        self.width = math.max(iconWidth) + 20 -- TODO: Non-hardcoded padding

		local iconHeight = 0
		if (self.image) then
			iconHeight = self.image:getHeight()
		end

		self.height = math.max(iconHeight) + 20
	end
end

function Image:refreshImage()
	if (self.image) then
		self.image:release()
	end

	self.image = love.graphics.newImage(self.imagePath)
end

function Image:performDraw(x, y, width, height)
	x, y = self:getPosition()

	if (self.image) then
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(self.image, x, y, 0, width / self.image:getWidth(), height / self.image:getHeight())
	end
end

return Image
