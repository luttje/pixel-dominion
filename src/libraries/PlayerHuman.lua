local Player = require('libraries.Player')

--- @class PlayerHuman : Player
---
--- @field inputBlocked boolean
--- @field worldInputBlockedBy any
--- @field currentStructureToBuild StructureTypeRegistry.StructureRegistration|nil
--- @field currentStructureBuilders Unit[]|nil
--- @field currentStructureBuildPosition table|nil
--- @field selectedInteractables InteractableGroup
local PlayerHuman = DeclareClassWithBase('PlayerHuman', Player)

function PlayerHuman:initialize(config)
	config = config or {}

	self.inputBlocked = false
	self.worldInputBlockedBy = nil
	self.selectedInteractables = InteractableGroup()

	table.Merge(self, config)
end

--- Returns if the player is blocked from clicking buttons
--- @return boolean
function PlayerHuman:isInputBlocked()
	return self.inputBlocked
end

--- Blocks the player from clicking buttons
--- @param block boolean
function PlayerHuman:setInputBlocked(block)
	self.inputBlocked = block
end

--- Returns what is blocking the player from clicking the world
--- @return any
function PlayerHuman:getWorldInputBlocker()
	return self.worldInputBlockedBy
end

--- Blocks the player from clicking the world
--- @param blocker any
function PlayerHuman:setWorldInputBlockedBy(blocker)
	self.worldInputBlockedBy = blocker
end

--- Adds the given interactable to the selected interactables
--- @param interactable Interactable
function PlayerHuman:addSelectedInteractable(interactable)
	self.selectedInteractables:add(interactable)
end

--- Removes the given interactable from the selected interactables
--- @param interactable Interactable
function PlayerHuman:removeSelectedInteractable(interactable)
	self.selectedInteractables:remove(interactable)
end

--- Selects all interactables similar to the selected interactables
function PlayerHuman:selectAllInteractablesOfSameType()
	local allInteractables = self:getFaction():getInteractables()
	local allSelectedInteractables = self.selectedInteractables:getAll()

	if (#allSelectedInteractables == 0) then
		return
	end

	local function isOfSameType(interactable)
		for i, selectedInteractable in ipairs(allSelectedInteractables) do
			if (
					selectedInteractable:getFaction() == interactable:getFaction()
					and selectedInteractable:isOfType(getmetatable(interactable))
				) then
				if (selectedInteractable:isOfType(Unit) and selectedInteractable:getUnitType() == interactable:getUnitType()) then
					return true
				elseif (selectedInteractable:isOfType(Structure) and selectedInteractable:getStructureType() == interactable:getStructureType()) then
					return true
				end
			end
		end

		return false
	end

	for i, interactable in ipairs(allInteractables) do
		if (isOfSameType(interactable)) then
			interactable:setSelected(true)
		end
	end
end

--- Clears the selected interactables
function PlayerHuman:clearSelectedInteractables()
	self.selectedInteractables:clear()
end

--- Checks if the given interactable is of the same type as those in the selected interactables
--- @param interactable Interactable
--- @return boolean
function PlayerHuman:isSameTypeAsSelected(interactable)
	if (#self.selectedInteractables:getAll() == 0) then
		return true
	end

	local firstInteractable = self.selectedInteractables:getAll()[1]
	return firstInteractable:isOfType(getmetatable(interactable))
end

--- Gets the selected interactables
--- @return Interactable[]
function PlayerHuman:getSelectedInteractables()
	return self.selectedInteractables:getAll()
end

--- Sends a command to any interactables that can handle it.
--- Units will use this to move to a target position, attack a target, etc.
--- @param targetX number
--- @param targetY number
--- @param targetInteractable Interactable
function PlayerHuman:sendCommandTo(targetX, targetY, targetInteractable)
	local allSelectedInteractables = self.selectedInteractables:getAll()
	local sizeOfAllSelectedInteractables = #allSelectedInteractables

	if (sizeOfAllSelectedInteractables == 0) then
		return
	end

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

--- Sets the current structure to build
--- @param structureType StructureTypeRegistry.StructureRegistration
--- @param units Unit[]
function PlayerHuman:setCurrentStructureToBuild(structureType, units)
	self.currentStructureToBuild = structureType
	self.currentStructureBuilders = units
end

--- Gets the current structure to build
--- @return StructureTypeRegistry.StructureRegistration, Unit[], table
function PlayerHuman:getCurrentStructureToBuild()
	return self.currentStructureToBuild, self.currentStructureBuilders, self.currentStructureBuildPosition
end

--- Sets the position for the current structure to build
--- @param x number
--- @param y number
--- @param canPlace boolean
function PlayerHuman:setCurrentStructureBuildPosition(x, y, canPlace)
	if (not canPlace) then
		self.currentStructureBuildPosition = nil
		return
	end

	self.currentStructureBuildPosition = { x = x, y = y }
end

--- Clears the current structure to build
function PlayerHuman:clearCurrentStructureToBuild()
	self.currentStructureToBuild = nil
	self.currentStructureBuilders = nil
	self.currentStructureBuildPosition = nil
end

return PlayerHuman
