--- Displays a single resource type
--- @class ResourceIndicator: InterfaceFragment
---
--- @field resourceType ResourceTypeRegistry.ResourceRegistration
--- @field value number|nil # The value to display, if nil, it will be fetched from the player faction resource inventory
---
--- @field isEnabled boolean
--- @field iconsImageData table<number, love.ImageData>
--- @field iconsImage table<number, love.Image>
local ResourceIndicator = DeclareClassWithBase('ResourceIndicator', InterfaceFragment)

function ResourceIndicator:initialize(config)
    assert(config.resourceType, 'Resource type is required.')

	self:setEnabled(true)

    table.Merge(self, config)

	self:refreshIconImage()
end

--- Sets whether the resource indicator is enabled (non-greyed out)
--- @param isEnabled boolean
function ResourceIndicator:setEnabled(isEnabled)
    if (self.isEnabled == isEnabled) then
        return
    end

    self.isEnabled = isEnabled
	self:refreshIconImage()
end

--- Gets if the resource indicator is enabled
--- @return boolean
function ResourceIndicator:getEnabled()
    return self.isEnabled
end

--- Refreshes the icon image
function ResourceIndicator:refreshIconImage()
	if (self.iconImageData) then
        self.iconImageData:release()
		self.iconImage:release()
	end
	if (self:getEnabled()) then
		self.iconImage = ImageCache:get(self.resourceType.imagePath)
	else
		local iconImageData = love.image.newImageData(self.resourceType.imagePath)
		iconImageData:mapPixel(function(x, y, r, g, b, a)
			local gray = (r + g + b) / 3
			return gray, gray, gray, a
		end)

		self.iconImageData = iconImageData
		self.iconImage = love.graphics.newImage(iconImageData)
	end
end

function ResourceIndicator:getValue()
    if (self.value) then
        return self.value
    end

	local faction = CurrentPlayer:getFaction()
    local resourceAmount = faction:getResourceInventory():getValue(self.resourceType) or 0

	if (self.resourceType.formatValue) then
		resourceAmount = self.resourceType:formatValue(resourceAmount)
	end

	return resourceAmount
end

function ResourceIndicator:performDraw(x, y, width, height)
	local resourceType = self.resourceType
    local resourceValue = self:getValue()

    -- We draw the resource icon and text centered in the middle of the resource indicator
    local text = love.graphics.newText(Fonts.resourceValue, resourceValue)
    local textWidth = text:getWidth()
    local iconSize = math.min(width * 0.2, height * 0.8)

    local iconX = x + (width - iconSize - textWidth - Sizes.padding()) * 0.5
    local iconY = y + (height - iconSize) * 0.5

    love.graphics.setColor(1, 1, 1)
	love.graphics.draw(self.iconImage, iconX, iconY, 0, iconSize / self.iconImage:getWidth(), iconSize / self.iconImage:getHeight())

    if (tonumber(resourceValue) and tonumber(resourceValue) < 0) then
        love.graphics.setColor(1, 0.2, 0.2)
    else
        love.graphics.setColor(0, 0, 0)
    end

    love.graphics.draw(text, iconX + iconSize + Sizes.padding(), y + (height - text:getHeight()) * 0.5)
end

return ResourceIndicator
