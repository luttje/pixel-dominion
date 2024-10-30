local FactionProfileIndicator = require('interface-fragments.FactionProfileIndicator')

--- Displays all faction profiles
--- @class FactionProfiles: InterfaceFragment
local FactionProfiles = DeclareClassWithBase('FactionProfiles', InterfaceFragment)

function FactionProfiles:initialize(config)
	self.isClippingDisabled = true

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

--- Draws speech bubbles from factions, if they have any. So the player can understand
--- what the AI is thinking.
--- @param x number
--- @param y number
--- @param width number
--- @param height number
function FactionProfiles:performDraw(x, y, width, height)
	for _, factionProfileIndicator in ipairs(self.factionProfileIndicators) do
		local centerX, centerY = factionProfileIndicator:getVisualCenter()

		self:drawSpeechBubble(x + centerX, y, factionProfileIndicator.faction)
	end
end

--- This function draws a speech bubble for a faction, if they have any speech.
--- @param x number
--- @param y number
--- @param faction Faction
function FactionProfiles:drawSpeechBubble(x, y, faction)
	local text, alphaFactor = faction.speechLog:getCurrentSpeech()

	if (not text) then
		return
	end

	local font = Fonts.default
	local widthPerFaction = (self:getWidth() / #self.factionProfileIndicators) * 0.8
	local textWidth, wrappedText = font:getWrap(text, widthPerFaction)
	local textHeight = #wrappedText * font:getHeight()

	local padding = Sizes.padding()
	local bubbleWidth = textWidth + padding * 2
	local bubbleHeight = textHeight + padding * 2

	y = y - textHeight - (padding * 4)

	love.graphics.setColor(1, 1, 1, 0.5 * alphaFactor)
	love.graphics.roundRect('fill', x - bubbleWidth * 0.5, y, bubbleWidth, bubbleHeight, 12)

	-- Draw a little triangle pointing down to the faction
	love.graphics.polygon('fill', {
		x - 5, y + bubbleHeight,
		x + 5, y + bubbleHeight,
		x, y + bubbleHeight + padding,
	})

	love.graphics.setColor(0, 0, 0, 1 * alphaFactor)
	love.graphics.setFont(font)
	love.graphics.printf(wrappedText, x - textWidth * 0.5, y + padding, textWidth, 'center')
end


return FactionProfiles
