--- Displays a single faction profile
--- @class FactionProfileIndicator: InterfaceFragment
---
--- @field faction Faction
--- @field isWithoutBackground boolean
--- @field isWithoutText boolean
local FactionProfileIndicator = DeclareClassWithBase('FactionProfileIndicator', InterfaceFragment)

function FactionProfileIndicator:initialize(config)
	assert(config.faction, 'Faction is required.')

	self.isClippingDisabled = true
	self.isWithoutBackground = false
	self.isWithoutText = false

	table.Merge(self, config)
end

function FactionProfileIndicator:performDraw(x, y, width, height)
	local faction = self.faction

	-- TODO: Whatever calls this draw function should do this...
	x = self.parentContainer.ownerFragment:getX() + x
	y = self.parentContainer.ownerFragment:getY() + y

	local iconSize = height * 0.8
	local iconX = x + (width * 0.5) - (iconSize * 0.5)
	local iconY = y + (height * 0.5) - (iconSize * 0.5)

	local name = faction.factionType.name

	if (faction:getPlayer() == CurrentPlayer) then
		name = 'You'
	end

	local text = love.graphics.newText(Fonts.resourceValue, name)
	local textWidth = text:getWidth()

	local textX = 0
	local textY = 0

	if (not self.isWithoutText) then
		textX = x + (width * 0.5) - (textWidth * 0.5)
		textY = y + height - text:getHeight()
	end

	if (not self.isWithoutBackground) then
		-- Draw a black box behind the text and icon so it's readable
		local padding = Sizes.padding()
		local roundedColors = {
			{ 0, 0, 0, 0.4 },
		}
		local color, highlightColor = self.faction:getColors()
		color[4] = 0.5

		table.insert(roundedColors, color)

		for i = 1, #roundedColors do
			love.graphics.setColor(unpack(roundedColors[i]))
			love.graphics.roundRect(
				'fill',
				math.min(iconX, textX) - padding,
				math.min(iconY, textY) - padding,
				math.max(iconSize, textWidth) + (padding * 2),
				math.max(iconSize, text:getHeight()) + (padding * 4),
				12
			)
		end
	end

	love.graphics.setColor(1, 1, 1)
	faction.factionType:drawProfileImage(iconX, iconY, iconSize, iconSize)

	if (not self.isWithoutText) then
		love.graphics.setColor(Colors.text())
		love.graphics.draw(text, textX, textY)
	end
end

return FactionProfileIndicator
