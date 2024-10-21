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
        self.resourceValues[resourceType.id] = resourceType:newValue()
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

--- Gets the resource value for the given resource type
--- @param resourceType ResourceTypeRegistry.ResourceRegistration
--- @return ResourceValue
function ResourceInventory:getValue(resourceType)
	return self.resourceValues[resourceType.id]
end

--- Adds the given amount of resources to the faction
--- @param resourceType ResourceTypeRegistry.ResourceRegistration
--- @param amount number
function ResourceInventory:add(resourceType, amount)
    self.resourceValues[resourceType.id].value = self.resourceValues[resourceType.id].value + amount

	self.currentResources = self.currentResources + amount
end

--- Removes the given amount of resources from the faction
--- @param resourceType ResourceTypeRegistry.ResourceRegistration
--- @param amount number
function ResourceInventory:remove(resourceType, amount)
	self.resourceValues[resourceType.id].value = self.resourceValues[resourceType.id].value - amount

	self.currentResources = self.currentResources - amount
end

--- Checks if the faction has enough resources
--- @param resourceType ResourceTypeRegistry.ResourceRegistration
--- @param amount number
--- @return boolean
function ResourceInventory:has(resourceType, amount)
    return self.resourceValues[resourceType.id].value >= amount
end

--- Returns all resource values
--- @return ResourceValue[]
function ResourceInventory:getAll()
	return self.resourceValues
end

return ResourceInventory
