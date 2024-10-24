--- Displays a single resource type
--- @class ResourceIndicator: InterfaceFragment
--- @field resourceType ResourceTypeRegistry.ResourceRegistration
local ResourceIndicator = DeclareClassWithBase('ResourceIndicator', InterfaceFragment)

function ResourceIndicator:initialize(config)
    assert(config.resourceType, 'Resource type is required.')

    table.Merge(self, config)
end

function ResourceIndicator:getValue()
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
    resourceType:draw(iconX, iconY, iconSize, iconSize)

    love.graphics.setColor(0, 0, 0)
    love.graphics.draw(text, iconX + iconSize + Sizes.padding(), y + (height - text:getHeight()) * 0.5)
end

return ResourceIndicator
