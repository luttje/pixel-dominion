--- Represents a resource value in the game
--- @class ResourceInstance : Interactable
--- @field resourceType ResourceTypeRegistry.ResourceRegistration
--- @field supply number
--- @field tileWidth number
--- @field tileHeight number
local ResourceInstance = DeclareClassWithBase('ResourceInstance', Interactable)

--- Initializes the faction
--- @param config table
function ResourceInstance:initialize(config)
    config = config or {}

	self.isSelectable = false

	table.Merge(self, config)
end

--- Gets the type of resource
--- @return ResourceTypeRegistry.ResourceRegistration
function ResourceInstance:getResourceType()
    return self.resourceType
end

--- When an interactable is interacted with
--- @param interactable Interactable
function ResourceInstance:interact(interactable)
    if (not interactable:isOfType(Unit)) then
        print('Cannot interact with resource as it is not a unit.')
        return
    end

    -- Set the action to 'action'
	interactable.currentAction = {
		animation = 'action',
		targetInteractable = self,
	}
end

return ResourceInstance
