--- Represents an inventory of resource values
--- @class ResourceInventory
--- @field resourceValues ResourceValue[]
--- @field maxResources number|nil
local ResourceInventory = DeclareClass('ResourceInventory')

--- Initializes the faction
--- @param config table
function ResourceInventory:initialize(config)
	config = config or {}

    self.resourceValues = {}
	self.maxResources = nil
	self.currentResources = 0

    for _, resourceType in pairs(ResourceTypeRegistry:getAllResourceTypes()) do
		local resourceValue = resourceType:newValue()

		if (config.withDefaultValues) then
			resourceValue.value = resourceType.defaultValue or 0
		end

        self.resourceValues[resourceType.id] = resourceValue
    end

	table.Merge(self, config)
end

--- Updates the current resources count
--- @field delta number
function ResourceInventory:updateCurrentResources(delta)
	self.currentResources = self.currentResources + delta
end

--- Gets the current resources count
--- @return number
function ResourceInventory:getCurrentResources()
	return self.currentResources
end

--- Gets the remaining resource space
--- @return number
function ResourceInventory:getRemainingResourceSpace()
	if (not self.maxResources) then
		return math.huge
	end

	return self.maxResources - self.currentResources
end

--- Whether the inventory is full
--- @return boolean
function ResourceInventory:isFull()
	if (not self.maxResources) then
		return false
	end

	return self.currentResources >= self.maxResources
end

--- Sets the maximum resources
--- @param maxResources number
function ResourceInventory:setMaxResources(maxResources)
	self.maxResources = maxResources
end

--- Gets the maximum resources
--- @return number
function ResourceInventory:getMaxResources()
	return self.maxResources
end

--- @param resourceTypeOrId ResourceTypeRegistry.ResourceRegistration|string
--- @return string
function ResourceInventory:resolveResourceTypeId(resourceTypeOrId)
	return type(resourceTypeOrId) == 'string' and resourceTypeOrId or resourceTypeOrId.id
end

--- Gets the resource value for the given resource type
--- @param resourceTypeOrId ResourceTypeRegistry.ResourceRegistration|string
--- @return number
function ResourceInventory:getValue(resourceTypeOrId)
    local resourceTypeId = self:resolveResourceTypeId(resourceTypeOrId)

	return self.resourceValues[resourceTypeId].value
end

--- Adds the given amount of resources to the faction
--- @param resourceTypeOrId ResourceTypeRegistry.ResourceRegistration|string
--- @param amount number
function ResourceInventory:add(resourceTypeOrId, amount)
	local resourceTypeId = self:resolveResourceTypeId(resourceTypeOrId)

    self.resourceValues[resourceTypeId].value = self.resourceValues[resourceTypeId].value + amount

    self.currentResources = self.currentResources + amount
end

--- Removes the given amount of resources from the faction
--- @param resourceTypeOrId ResourceTypeRegistry.ResourceRegistration|string
--- @param amount number
function ResourceInventory:remove(resourceTypeOrId, amount)
	local resourceTypeId = self:resolveResourceTypeId(resourceTypeOrId)

	self.resourceValues[resourceTypeId].value = self.resourceValues[resourceTypeId].value - amount

	self.currentResources = self.currentResources - amount
end

--- Clears the resource inventory
function ResourceInventory:clear()
	for _, resourceType in pairs(ResourceTypeRegistry:getAllResourceTypes()) do
		self.resourceValues[resourceType.id].value = 0
	end

	self.currentResources = 0
end

--- Checks if the faction has enough resources
--- @param resourceTypeOrId ResourceTypeRegistry.ResourceRegistration|string
--- @param amount number
--- @return boolean
function ResourceInventory:has(resourceTypeOrId, amount)
	local resourceTypeId = self:resolveResourceTypeId(resourceTypeOrId)

    return self.resourceValues[resourceTypeId].value >= amount
end

--- Returns all resource values that are not zero
--- @return ResourceValue[]
function ResourceInventory:getAll()
	local resources = {}

	for _, resourceValue in pairs(self.resourceValues) do
		if (resourceValue.value > 0) then
			resources[resourceValue.resourceType.id] = resourceValue
		end
	end

	return resources
end

return ResourceInventory
