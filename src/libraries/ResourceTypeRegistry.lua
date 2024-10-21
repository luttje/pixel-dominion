--- @class ResourceTypeRegistry
local ResourceTypeRegistry = DeclareClass('ResourceTypeRegistry')

--[[
	ResourceRegistration
--]]

--- @class ResourceTypeRegistry.ResourceRegistration
--- @field id string The unique id of the resource type.
--- @field name string The name of the resource type.
--- @field image Image The image representing the resource type.
ResourceTypeRegistry.ResourceRegistration = DeclareClass('ResourceTypeRegistry.ResourceRegistration')

function ResourceTypeRegistry.ResourceRegistration:initialize(config)
	assert(config.id, 'Resource id is required.')
	assert(config.imagePath, 'Resource imagePath is required.')

	self.image = ImageCache:get(config.imagePath)

	config = config or {}

	table.Merge(self, config)
end

--- Draws the resource type icon
--- @param x number
--- @param y number
--- @param width number
--- @param height number
function ResourceTypeRegistry.ResourceRegistration:draw(x, y, width, height)
	love.graphics.draw(self.image, x, y, 0, width / self.image:getWidth(), height / self.image:getHeight())
end

--[[
	Registry methods
--]]

local registeredResourceTypes = {}

function ResourceTypeRegistry:registerResourceType(resourceId, config)
	config = config or {}
	config.id = resourceId

	registeredResourceTypes[resourceId] = ResourceTypeRegistry.ResourceRegistration(config)

	return registeredResourceTypes[resourceId]
end

function ResourceTypeRegistry:removeResourceType(resourceId)
	registeredResourceTypes[resourceId] = nil
end

function ResourceTypeRegistry:getResourceType(resourceId)
	return registeredResourceTypes[resourceId]
end

function ResourceTypeRegistry:getAllResourceTypes()
	local resourceConfigs = {}

	for _, config in pairs(registeredResourceTypes) do
		table.insert(resourceConfigs, config)
	end

	return resourceConfigs
end

return ResourceTypeRegistry
