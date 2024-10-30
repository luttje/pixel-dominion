local FactionProfileIndicator = require('interface-fragments.FactionProfileIndicator')

--- Displays all faction profiles
--- @class FactionProfiles: InterfaceFragment
local FactionProfiles = DeclareClassWithBase('FactionProfiles', InterfaceFragment)

function FactionProfiles:initialize(config)
	table.Merge(self, config)

	self.factionProfileIndicators = {}

	local factions = {}

	-- Only non-player factions
	for _, faction in ipairs(CurrentPlayer:getWorld():getFactions()) do
		if (faction ~= CurrentPlayer:getFaction()) then
			table.insert(factions, faction)
		end
	end

	local percentageWidth = 1 / #factions * 100

	for i, faction in ipairs(factions) do
		local factionProfileIndicator = FactionProfileIndicator({
			faction = faction,

			x = 0,
			y = 0,

			width = percentageWidth .. '%',
			height = '100%',
		})

		self.childFragments:add(factionProfileIndicator)
		table.insert(self.factionProfileIndicators, factionProfileIndicator)
	end
end

--- On update we stack the faction profile indicators next to each other
--- @param deltaTime number
--- @param isPointerWithin boolean
function FactionProfiles:performUpdate(deltaTime, isPointerWithin)
	local shadowHeight = Sizes.padding()
	local x = 0

	for _, factionProfileIndicator in ipairs(self.factionProfileIndicators) do
		local width = factionProfileIndicator:getWidth()
		factionProfileIndicator:setX(x)
		factionProfileIndicator:setHeight(self:getHeight() - shadowHeight)

		x = x + width
	end
end

return FactionProfiles
