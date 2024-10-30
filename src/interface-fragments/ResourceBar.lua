require('interface-fragments.ResourceIndicator')

--- Displays all the resources the player has
--- @class ResourceBar: InterfaceFragment
local ResourceBar = DeclareClassWithBase('ResourceBar', InterfaceFragment)

function ResourceBar:initialize(config)
    assert(CurrentPlayer, 'Player is required.')

	table.Merge(self, config)

	self.factionProfileIndicator = FactionProfileIndicator({
		faction = CurrentPlayer:getFaction(),

		x = 0,
		y = 0,

		width = '100%',
		height = '50%',

		isWithoutBackground = true,
		isWithoutText = true,
	})
	self.childFragments:add(self.factionProfileIndicator)

    self.resourceIndicators = {}

    local types = ResourceTypeRegistry:getAllResourceTypes()
	local shadowHeight = Sizes.padding()
	local percentageWidth = 1 / #types * 100

    for i, resourceType in ipairs(types) do
		local resourceIndicator = ResourceIndicator({
            resourceType = resourceType,
			faction = CurrentPlayer:getFaction(),

            x = 0,
			anchorVertically = 'end',
			alignVertically = 'end',
			anchorMargins = { bottom = shadowHeight },

            width = percentageWidth .. '%',
			height = '50%',
		})

		self.childFragments:add(resourceIndicator)
		table.insert(self.resourceIndicators, resourceIndicator)
	end
end

--- On update we stack the resource indicators next to each other
--- @param deltaTime number
--- @param isPointerWithin boolean
function ResourceBar:performUpdate(deltaTime, isPointerWithin)
	local x = 0

	for _, resourceIndicator in ipairs(self.resourceIndicators) do
		local width = resourceIndicator:getWidth()
        resourceIndicator:setX(x)

		x = x + width
	end
end

function ResourceBar:performDraw(x, y, width, height)
	local shadowHeight = Sizes.padding()
    local resourceHeight = height - shadowHeight

    -- TODO: Draw a nice textured  background for the resource bar
    love.graphics.setColor(0, 0, 0, 0.2)
	love.graphics.rectangle('fill', x, y, width, height)
    love.graphics.setColor(0.2, 0.5, 0.5)
    love.graphics.rectangle('fill', x, y, width, resourceHeight)
end

return ResourceBar
