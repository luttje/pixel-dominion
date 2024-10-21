--- Represents a group of interactable objects in the world
--- @class InteractableGroup
--- @field interactables Interactable[] # The interactables in the group
local InteractableGroup = DeclareClass('InteractableGroup')

--- Initializes the unit
--- @param config table
function InteractableGroup:initialize(config)
	config = config or {}

	self.interactables = {}

	table.Merge(self, config)
end

--- Adds the given interactable to the group
--- @param interactable Interactable
function InteractableGroup:add(interactable)
    table.insert(self.interactables, interactable)
end

--- Removes the given interactable from the group
--- @param interactable Interactable
function InteractableGroup:remove(interactable)
    for i, v in ipairs(self.interactables) do
        if (v == interactable) then
            table.remove(self.interactables, i)
            return
        end
    end
end

--- Clears all interactables from the group
function InteractableGroup:clear()
    -- Set the interactables all to not be selected
	for _, interactable in ipairs(self.interactables) do
		interactable:setSelected(false)
	end

	table.Empty(self.interactables)
end

--- Gets all interactables in the group
--- @return Interactable[]
function InteractableGroup:getAll()
	return self.interactables
end

return InteractableGroup
