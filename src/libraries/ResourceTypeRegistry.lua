--- @class ResourceTypeRegistry
local ResourceTypeRegistry = DeclareClass('ResourceTypeRegistry')

--[[
	ResourceRegistration
--]]

--- @class ResourceTypeRegistry.ResourceRegistration
--- @field id string The unique id of the resource type.
--- @field name string The name of the resource type.
--- @field image Image The image representing the resource type.
--- @field defaultValue number The default value of the resource type.
--- @field formatValue fun(value: number): string A function that formats the value of the resource type.
ResourceTypeRegistry.ResourceRegistration = DeclareClass('ResourceTypeRegistry.ResourceRegistration')

function ResourceTypeRegistry.ResourceRegistration:initialize(config)
	assert(config.id, 'Resource id is required.')
	assert(config.imagePath, 'Resource imagePath is required.')

	self.image = ImageCache:get(config.imagePath)

	config = config or {}

	table.Merge(self, config)
end

--- Creates a new resource value instance
--- @return ResourceValue
function ResourceTypeRegistry.ResourceRegistration:newValue()
	return ResourceValue({
		resourceType = self,
		value = self.defaultValue or 0
	})
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
local registeredResourceTypeMap = {}

function ResourceTypeRegistry:registerResourceType(resourceId, config)
	config = config or {}
	config.id = resourceId

    local index = #registeredResourceTypes + 1
    registeredResourceTypes[index] = ResourceTypeRegistry.ResourceRegistration(config)
	registeredResourceTypeMap[resourceId] = index

	return registeredResourceTypes[resourceId]
end

function ResourceTypeRegistry:removeResourceType(resourceId)
	local index = registeredResourceTypeMap[resourceId]

	if (index) then
		registeredResourceTypes[index] = nil
		registeredResourceTypeMap[resourceId] = nil
	end
end

function ResourceTypeRegistry:getResourceType(resourceId)
	local index = registeredResourceTypeMap[resourceId]

	if (index) then
		return registeredResourceTypes[index]
	end

	return nil
end

function ResourceTypeRegistry:getAllResourceTypes()
	return registeredResourceTypes
end

return ResourceTypeRegistry
