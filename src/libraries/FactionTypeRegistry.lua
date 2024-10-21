--- @class FactionTypeRegistry
local FactionTypeRegistry = DeclareClass('FactionTypeRegistry')

--[[
	FactionRegistration
--]]

--- @class FactionTypeRegistry.FactionRegistration
--- @field id string The unique id of the faction.
--- @field name string The name of the faction.
FactionTypeRegistry.FactionRegistration = DeclareClass('FactionTypeRegistry.FactionRegistration')

function FactionTypeRegistry.FactionRegistration:initialize(config)
	assert(config.id, 'Faction id is required.')

	config = config or {}

	table.Merge(self, config)
end

--[[
	Registry methods
--]]

local registeredFactionTypes = {}

function FactionTypeRegistry:registerFactionType(factionId, config)
	config = config or {}
	config.id = factionId

	registeredFactionTypes[factionId] = FactionTypeRegistry.FactionRegistration(config)

	return registeredFactionTypes[factionId]
end

function FactionTypeRegistry:removeFactionType(factionId)
	registeredFactionTypes[factionId] = nil
end

function FactionTypeRegistry:getFactionType(factionId)
	return registeredFactionTypes[factionId]
end

function FactionTypeRegistry:getAllFactionTypes()
	local factionConfigs = {}

	for _, config in pairs(registeredFactionTypes) do
		table.insert(factionConfigs, config)
	end

	return factionConfigs
end

return FactionTypeRegistry
