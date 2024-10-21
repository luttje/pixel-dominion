--- Represents a resource value in the game
--- @class ResourceValue
--- @field resourceType ResourceTypeRegistry.ResourceRegistration
--- @field value number
local ResourceValue = DeclareClass('ResourceValue')

--- Initializes the faction
--- @param config table
function ResourceValue:initialize(config)
	config = config or {}

	table.Merge(self, config)
end

--- Gets the type of resource
--- @return ResourceTypeRegistry.ResourceRegistration
function ResourceValue:getResourceType()
    return self.resourceType
end

return ResourceValue
