--- @class FactionTypeRegistry
local FactionTypeRegistry = DeclareClass('FactionTypeRegistry')

--[[
	FactionRegistration
--]]

--- @class FactionTypeRegistry.FactionRegistration
--- @field id string The unique id of the faction.
--- @field name string The name of the faction.
--- @field profileImage Image The profile image of the faction.
--- @field profileImageQuad Quad The quad determining which part of the profile image to display.
FactionTypeRegistry.FactionRegistration = DeclareClass('FactionTypeRegistry.FactionRegistration')

local QUAD_SIZE = 32

function FactionTypeRegistry.FactionRegistration:initialize(config)
	assert(config.id, 'Faction id is required.')

	config = config or {}

	table.Merge(self, config)
end

function FactionTypeRegistry.FactionRegistration:initProfileImageIfNeeded()
	if (self.profileImage) then
		return
	end

	self.profileImage = ImageCache:get(self.profileImagePath)
	-- TODO: Different quads based on emotion of the faction
	self.profileImageQuad = love.graphics.newQuad(0, 0, QUAD_SIZE, QUAD_SIZE, self.profileImage:getDimensions())
end

--- Draws the faction profile image
--- @param x number
--- @param y number
--- @param width number
--- @param height number
function FactionTypeRegistry.FactionRegistration:drawProfileImage(x, y, width, height)
	self:initProfileImageIfNeeded()

	love.graphics.draw(self.profileImage, self.profileImageQuad, x, y, 0, width / QUAD_SIZE, height / QUAD_SIZE)
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
