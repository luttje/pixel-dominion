--- Represents a faction in the game
--- @class Faction
--- @field factionType FactionTypeRegistry.FactionRegistration
--- @field resourceValues ResourceValue[] # How many resources the faction has
--- @field units table<number, Unit> # The units in the world
--- @field structures table<number, Structure> # The structures in the world
local Faction = DeclareClass('Faction')

--- Initializes the faction
--- @param config table
function Faction:initialize(config)
	config = config or {}

	self.resourceValues = {}
	self.units = {}
	self.structures = {}

	for _, resourceType in pairs(ResourceTypeRegistry:getAllResourceTypes()) do
		self.resourceValues[resourceType.id] = resourceType:newValue()
	end

    table.Merge(self, config)
end

--- Gets the type of faction
--- @return FactionTypeRegistry.FactionRegistration
function Faction:getFactionType()
	return self.factionType
end

--- Gets the resource value for the given resource type
--- @param resourceType ResourceTypeRegistry.ResourceRegistration
--- @return ResourceValue
function Faction:getResourceValue(resourceType)
	return self.resourceValues[resourceType.id]
end

--- Adds the given amount of resources to the faction
--- @param resourceType ResourceTypeRegistry.ResourceRegistration
--- @param amount number
function Faction:addResources(resourceType, amount)
    self.resourceValues[resourceType.id].value = self.resourceValues[resourceType.id].value + amount
end

--- Removes the given amount of resources from the faction
--- @param resourceType ResourceTypeRegistry.ResourceRegistration
--- @param amount number
function Faction:removeResources(resourceType, amount)
	self.resourceValues[resourceType.id].value = self.resourceValues[resourceType.id].value - amount
end

--- Checks if the faction has enough resources
--- @param resourceType ResourceTypeRegistry.ResourceRegistration
--- @param amount number
--- @return boolean
function Faction:hasResources(resourceType, amount)
    return self.resourceValues[resourceType.id].value >= amount
end

--- Returns all resource values
--- @return ResourceValue[]
function Faction:getResourceValues()
	return self.resourceValues
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
		currentAction = 'idle'
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
