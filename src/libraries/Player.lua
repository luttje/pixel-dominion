--- @class Player
--- @field inputBlocked boolean
--- @field worldInputBlockedBy any
--- @field currentStructureToBuild StructureTypeRegistry.StructureRegistration|nil
--- @field currentStructureBuilders Unit[]|nil
--- @field currentStructureBuildPosition table|nil
--- @field world World
--- @field faction Faction
--- @field selectedInteractables InteractableGroup
local Player = DeclareClass('Player')

function Player:initialize(config)
	config = config or {}

	self.inputBlocked = false
	self.worldInputBlockedBy = nil
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

--- Returns what is blocking the player from clicking the world
--- @return any
function Player:getWorldInputBlocker()
	return self.worldInputBlockedBy
end

--- Blocks the player from clicking the world
--- @param blocker any
function Player:setWorldInputBlockedBy(blocker)
	self.worldInputBlockedBy = blocker
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

--- Selects all interactables similar to the selected interactables
function Player:selectAllInteractablesOfSameType()
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
--- @return Interactable[]
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

	if (sizeOfAllSelectedInteractables == 0) then
		return
	end

	if (targetInteractable and targetInteractable.interactSounds) then
		targetInteractable:playSound(table.Random(targetInteractable.interactSounds))
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
function Player:setCurrentStructureToBuild(structureType, units)
	self.currentStructureToBuild = structureType
	self.currentStructureBuilders = units
end

--- Gets the current structure to build
--- @return StructureTypeRegistry.StructureRegistration, Unit[], table
function Player:getCurrentStructureToBuild()
	return self.currentStructureToBuild, self.currentStructureBuilders, self.currentStructureBuildPosition
end

--- Sets the position for the current structure to build
--- @param x number
--- @param y number
--- @param canPlace boolean
function Player:setCurrentStructureBuildPosition(x, y, canPlace)
	if (not canPlace) then
		self.currentStructureBuildPosition = nil
		return
	end

	self.currentStructureBuildPosition = { x = x, y = y }
end

--- Clears the current structure to build
function Player:clearCurrentStructureToBuild()
	self.currentStructureToBuild = nil
	self.currentStructureBuilders = nil
	self.currentStructureBuildPosition = nil
end

return Player
