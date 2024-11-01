--- @class FactionTypeRegistry
local FactionTypeRegistry = DeclareClass('FactionTypeRegistry')

--[[
	FactionRegistration
--]]

--- @class FactionTypeRegistry.FactionRegistration
---
--- @field id string The unique id of the faction.
--- @field name string The name of the faction.
---
--- @field profileImage Image The profile image of the faction.
--- @field profileImageQuad Quad The quad determining which part of the profile image to display.
---
--- @field directiveSpeeches table<string, table> A table of things the faction can say when a directive is completed.
--- @field checkShouldSurrender? fun(factionType: FactionTypeRegistry.FactionRegistration, faction: Faction): boolean A function that determines if the faction should surrender.
--- @field onSurrender? fun(factionType: FactionTypeRegistry.FactionRegistration, faction: Faction): table A function that is called when the faction surrenders, returning a table of things the faction can say.
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
--- @param faction Faction
--- @param x number
--- @param y number
--- @param width number
--- @param height number
function FactionTypeRegistry.FactionRegistration:drawProfileImage(faction, x, y, width, height)
	self:initProfileImageIfNeeded()

	if (faction.isDefeated) then
		-- Draw a grayed out version of the profile image
		if (not faction.greyedOutProfileImage) then
            local imageData = love.image.newImageData(self.profileImagePath)
			imageData:mapPixel(function(x, y, r, g, b, a)
				local gray = (r + g + b) / 3
				return gray, gray, gray, a
            end)

			faction.greyedOutProfileImage = love.graphics.newImage(imageData)
		end

		love.graphics.draw(faction.greyedOutProfileImage, self.profileImageQuad, x, y, 0, width / QUAD_SIZE, height / QUAD_SIZE)
		return
	end

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
