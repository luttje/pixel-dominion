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

return Faction
