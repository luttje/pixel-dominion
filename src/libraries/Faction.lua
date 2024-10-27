--- Clear constant to show that placement is free
FORCE_FREE_PLACEMENT = true

--- Represents a faction in the game
--- @class Faction
---
--- @field factionType FactionTypeRegistry.FactionRegistration
--- @field world World|nil
--- @field player Player
---
--- @field resourceInventory ResourceInventory
--- @field units table<number, Unit> # The units in the world
--- @field structures table<number, Structure> # The structures in the world
local Faction = DeclareClass('Faction')

--- Initializes the faction
--- @param config table
function Faction:initialize(config)
    assert(config.factionType, 'Faction must have a faction type.')
	assert(config.player, 'Faction must have a player.')

	self.resourceInventory = ResourceInventory({
		withDefaultValues = true,
	})
	self.units = {}
	self.structures = {}

    table.Merge(self, config)

    self.player:setFaction(self)
end

--- Sets the world for the faction
--- @param world World
function Faction:setWorld(world)
    self.world = world
    self.player:setWorld(self.world)
end

--- Gets the world for the faction
--- @return World
function Faction:getWorld()
	return self.world
end

--- Gets the resource inventory
--- @return ResourceInventory
function Faction:getResourceInventory()
	return self.resourceInventory
end

--- Gets the type of faction
--- @return FactionTypeRegistry.FactionRegistration
function Faction:getFactionType()
	return self.factionType
end

--- Spawns a unit of the given type at the given position
--- @param unitType UnitTypeRegistry.UnitRegistration
--- @param x number
--- @param y number
--- @return Unit
function Faction:spawnUnit(unitType, x, y)
	local unit = Unit({
        unitType = unitType,
		faction = self,
		x = x,
		y = y,
		targetX = x,
		targetY = y,
        health = 100,
		world = self:getWorld(),
    })

	unit:onSpawn()

	table.insert(self.units, unit)

	return unit
end

--- Returns all units
--- @return Unit[]
function Faction:getUnits()
    return self.units
end

--- Returns all units of the given type
--- @param unitType UnitTypeRegistry.UnitRegistration|string
--- @return Unit[]
function Faction:getUnitsOfType(unitType)
	local units = {}

	for _, unit in ipairs(self.units) do
		if (unit.unitType.id == unitType or unit.unitType == unitType) then
			table.insert(units, unit)
		end
	end

	return units
end

--- Removes the unit from the faction
--- @param unit Unit
--- @return boolean # Whether the unit was removed
function Faction:removeUnit(unit)
	for i, factionUnit in ipairs(self.units) do
		if (factionUnit == unit) then
			table.remove(self.units, i)

			return true
		end
	end

	return false
end

--- Spawns a structure of the given type at the given position
--- @param structureType StructureTypeRegistry.StructureRegistration
--- @param x number
--- @param y number
--- @param builders? Unit[]
--- @param isFree? boolean
--- @return Structure
function Faction:spawnStructure(structureType, x, y, builders, isFree)
	assert(structureType.id == 'town_hall' or #self.structures > 0, 'Town hall must be spawned first.')

    if (not isFree) then
        structureType:subtractResources(self)
    end

	local structure = structureType:spawnAtTile(self:getWorld(), self, x, y, builders)

	table.insert(self.structures, structure)

	return structure
end

--- Returns all structures
--- @return Structure[]
function Faction:getStructures()
	return self.structures
end

--- Removes the structure from the faction
--- @param structure Structure
--- @return boolean # Whether the structure was removed
function Faction:removeStructure(structure)
	for i, factionStructure in ipairs(self.structures) do
		if (factionStructure == structure) then
			table.remove(self.structures, i)

			return true
		end
	end

	return false
end

--- Returns all structures of the given type
--- @param structureType StructureTypeRegistry.StructureRegistration|string
--- @return Structure[]
function Faction:getStructuresOfType(structureType)
	local structures = {}

	for _, structure in ipairs(self.structures) do
		if (structure.structureType.id == structureType or structure.structureType == structureType) then
			table.insert(structures, structure)
		end
	end

	return structures
end

--- Gets the town hall, always the first structure
--- @return Structure
function Faction:getTownHall()
	local townHall = self:getStructures()[1]

	assert(townHall, 'No town hall found.')

	return townHall
end

--- Called to perform logic on the faction
--- @param deltaTime number
function Faction:update(deltaTime)
	for _, unit in ipairs(self.units) do
		unit:update(deltaTime)
	end

	for _, structure in ipairs(self.structures) do
		structure:update(deltaTime)
	end
end

--- Returns both units and structures
--- @return table<number, Unit|Structure>
function Faction:getInteractables()
    local interactables = {}

    for _, unit in ipairs(self.units) do
        table.insert(interactables, unit)
    end

    for _, structure in ipairs(self.structures) do
        table.insert(interactables, structure)
    end

    return interactables
end

--- Returns the available structures for the faction
--- @return StructureTypeRegistry.StructureRegistration[]
function Faction:getAvailableStructures()
	local availableStructures = {}

	for _, structureType in pairs(StructureTypeRegistry:getAllStructureTypes()) do
		if (not structureType.isInternal) then
			table.insert(availableStructures, structureType)
		end
	end

	return availableStructures
end

return Faction
