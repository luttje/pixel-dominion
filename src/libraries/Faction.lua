require('libraries.ResourceInventory')

--- Represents a faction in the game
--- @class Faction
--- @field factionType FactionTypeRegistry.FactionRegistration
--- @field resourceInventory ResourceInventory
--- @field units table<number, Unit> # The units in the world
--- @field structures table<number, Structure> # The structures in the world
local Faction = DeclareClass('Faction')

--- Initializes the faction
--- @param config table
function Faction:initialize(config)
	config = config or {}

	self.resourceInventory = ResourceInventory()
	self.units = {}
	self.structures = {}

    table.Merge(self, config)
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
	})

	table.insert(self.units, unit)

	return unit
end

--- Returns all units
--- @return Unit[]
function Faction:getUnits()
    return self.units
end

--- Spawns a structure of the given type at the given position
--- @param structureType StructureTypeRegistry.StructureRegistration
--- @param x number
--- @param y number
--- @return Structure
function Faction:spawnStructure(structureType, x, y)
    assert(CurrentWorld, 'World is required to spawn a structure.')

	local structure = structureType:spawnAtTile(CurrentWorld, self, x, y)

	table.insert(self.structures, structure)

	return structure
end

--- Returns all structures
--- @return Structure[]
function Faction:getStructures()
    return self.structures
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

return Faction
