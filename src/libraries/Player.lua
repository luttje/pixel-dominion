--- @class Player
--- @field inputBlocked boolean
--- @field worldInputBlocked boolean
--- @field world World
--- @field faction Faction
--- @field selectedInteractables InteractableGroup
local Player = DeclareClass('Player')

function Player:initialize(config)
	config = config or {}

    self.inputBlocked = false
	self.worldInputBlocked = false
	self.selectedInteractables = InteractableGroup()

	table.Merge(self, config)
end

--- Returns if the player is blocked from clicking buttons
--- @return boolean
function Player:isInputBlocked()
	return self.inputBlocked
end

--- Blocks the player from clicking buttons
--- @param block boolean
function Player:setInputBlocked(block)
	self.inputBlocked = block
end

--- Returns if the player is blocked from clicking the world
--- @return boolean
function Player:isWorldInputBlocked()
	return self.worldInputBlocked
end

--- Blocks the player from clicking the world
--- @param block boolean
function Player:setWorldInputBlocked(block)
	self.worldInputBlocked = block
end

--- Sets the player world
--- @param world World
function Player:setWorld(world)
	self.world = world
end

--- Gets the player world
--- @return World
function Player:getWorld()
	return self.world
end

--- Sets the player faction
--- @param faction Faction
function Player:setFaction(faction)
    self.faction = faction
end

--- Gets the player faction
--- @return Faction
function Player:getFaction()
    return self.faction
end

--- Adds the given interactable to the selected interactables
--- @param interactable Interactable
function Player:addSelectedInteractable(interactable)
    self.selectedInteractables:add(interactable)
end

--- Removes the given interactable from the selected interactables
--- @param interactable Interactable
function Player:removeSelectedInteractable(interactable)
	self.selectedInteractables:remove(interactable)
end

--- Clears the selected interactables
function Player:clearSelectedInteractables()
	self.selectedInteractables:clear()
end

--- Checks if the given interactable is of the same type as those in the selected interactables
--- @param interactable Interactable
--- @return boolean
function Player:isSameTypeAsSelected(interactable)
	if (#self.selectedInteractables:getAll() == 0) then
		return true
	end

	local firstInteractable = self.selectedInteractables:getAll()[1]
	return firstInteractable:isOfType(getmetatable(interactable))
end

--- Gets the selected interactables
--- @return InteractableGroup
function Player:getSelectedInteractables()
    return self.selectedInteractables:getAll()
end

--- Sends a command to any interactables that can handle it.
--- Units will use this to move to a target position, attack a target, etc.
--- @param targetX number
--- @param targetY number
--- @param targetInteractable Interactable
function Player:sendCommandTo(targetX, targetY, targetInteractable)
    local allSelectedInteractables = self.selectedInteractables:getAll()
    local sizeOfAllSelectedInteractables = #allSelectedInteractables

	for i, interactable in ipairs(allSelectedInteractables) do
		if (interactable.commandTo) then
            interactable:commandTo(targetX, targetY, targetInteractable, {
				-- formation
				index = i,
                type = 'circle',
                size = sizeOfAllSelectedInteractables,
				centerUnit = allSelectedInteractables[1]
			})
		end
	end
end

return Player
