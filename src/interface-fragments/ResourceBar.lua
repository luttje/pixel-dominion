--- Displays all the resources the player has
--- @class ResourceBar: InterfaceFragment
local ResourceBar = DeclareClassWithBase('ResourceBar', InterfaceFragment)

function ResourceBar:initialize(config)
    assert(CurrentPlayer, 'Player is required.')

    table.Merge(self, config)

    self:refreshResources()
end

function ResourceBar:refreshResources()
    local faction = CurrentPlayer:getFaction()

    self.resourceValues = faction:getResourceInventory():getAll()
end

function ResourceBar:performDraw(x, y, width, height)
	local resourcesTypes = ResourceTypeRegistry:getAllResourceTypes()
    local resourceX = x
    local resourceY = y
    local resourceWidth = width / #resourcesTypes
	local shadowHeight = Sizes.padding()
    local resourceHeight = height - shadowHeight

    -- TODO: Draw a nice textured  background for the resource bar
    love.graphics.setColor(0, 0, 0, 0.2)
	love.graphics.rectangle('fill', x, y, width, height)
    love.graphics.setColor(0.2, 0.5, 0.5)
    love.graphics.rectangle('fill', x, y, width, resourceHeight)

    love.graphics.setFont(Fonts.resourceValue)
	local fontHeight = love.graphics.getFont():getHeight()

    for _, resourceType in pairs(resourcesTypes) do
        local resourceValue = self.resourceValues[resourceType.id]
        local resourceAmount = resourceValue.value

		if (resourceType.formatValue) then
			resourceAmount = resourceType:formatValue(resourceAmount)
		end

        -- Draw the resource icon on the center-left
        local iconSize = resourceHeight * 0.8
        local iconX = resourceX + 10
        local iconY = resourceY + (resourceHeight - iconSize) / 2

        love.graphics.setColor(1, 1, 1)
        resourceType:draw(iconX, iconY, iconSize, iconSize)

        -- Draw the resource amount next to the icon
        love.graphics.setColor(0, 0, 0)
		love.graphics.print(resourceAmount, iconX + iconSize + 10, resourceY + (resourceHeight - fontHeight) / 2)

        resourceX = resourceX + resourceWidth
    end
end


return ResourceBar
