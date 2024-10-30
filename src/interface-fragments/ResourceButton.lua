--- A button with resource icons indicating the cost of the action.
--- @class ResourceButton: Button
--- @field resourceInventory ResourceInventory # The inventory tracking the cost of the action
local ResourceButton = DeclareClassWithBase('ResourceButton', Button)

local RESOURCE_SECTION_HEIGHT = 0.5

--- Creates a new ResourceButton.
--- @param config table
function ResourceButton:initialize(config)
	assert(config.resourceInventory, 'ResourceButton requires a resourceInventory')

    table.Merge(self, config)

	self:refreshIndicators()
end

function ResourceButton:refreshIndicators()
    if (self.resourceIndicators) then
        for i, resourceIndicator in ipairs(self.resourceIndicators) do
            resourceIndicator:destroy()
        end
    end

    self.resourceIndicators = {}

	local resources = self.resourceInventory:getAll()
    local percentageWidth = 1 / #table.Values(resources) * 100

    for resourceTypeId, resource in pairs(resources) do
		local resourceIndicator = ResourceIndicator({
			resourceType = resource:getResourceType(),
			value = -resource.value,

			x = 0,
			y = 0,

			width = percentageWidth .. '%',
			height = (100 * RESOURCE_SECTION_HEIGHT) .. '%',
		})

		self.childFragments:add(resourceIndicator)
		table.insert(self.resourceIndicators, resourceIndicator)
    end
end

function ResourceButton:getTextY(y, height, textHeight)
    local iconsHeight = height * RESOURCE_SECTION_HEIGHT
	return y + (height - iconsHeight - textHeight) * 0.5
end

--- On update we stack the resource indicators next to each other
--- @param deltaTime number
--- @param isPointerWithin boolean
function ResourceButton:performUpdate(deltaTime, isPointerWithin)
	local x = 0

    for _, resourceIndicator in ipairs(self.resourceIndicators) do
        local width = resourceIndicator:getWidth()
        resourceIndicator:setEnabled(self:getEnabled())
        resourceIndicator:setPosition(x + self.x,
            self.y + (self.height - resourceIndicator:getHeight()) - Sizes.padding())

        x = x + width
    end

	self:getBase():performUpdate(deltaTime, isPointerWithin)
end

return ResourceButton
