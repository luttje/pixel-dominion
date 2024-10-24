--- Represents a button on the interface that can be clicked.
--- @class Button: InterfaceFragment
--- @field text string
--- @field iconImagePath string
---
--- @field wrapToContents boolean If true, the button will wrap to the size of the text and icon when created.
---
--- @field onClick fun(self: Button)
---
--- @field isEnabled boolean
--- @field isPressed boolean
--- @field isHovered boolean
---
--- @field font love.Font
--- @field isWithoutBackground boolean
local Button = DeclareClassWithBase('Button', InterfaceFragment)

--- Creates a new Button.
--- @param config any
function Button:initialize(config)
	self.isEnabled = true
	self.isPressed = false
	self.isHovered = false

	table.Merge(self, config)

	if (self.text and not self.font) then
		self:setFont(Fonts.buttonText)
	end

	if (self.iconImagePath) then
		self:refreshIconImage()
	end

	-- If no width or height is provided, calculate it based on the text and possible icon
	if (self.wrapToContents) then
		local textWidth = 0
		if (self.font and self.text) then
			textWidth = self.font:getWidth(self.text)
		end

		local iconWidth = 0
		if (self.iconImage) then
			iconWidth = self.iconImage:getWidth()
		end

        self.width = math.max(textWidth, iconWidth) + 20 -- TODO: Non-hardcoded padding

		local textHeight = 0
		if (self.font) then
			textHeight = self.font:getHeight()
		end

		local iconHeight = 0
		if (self.iconImage) then
			iconHeight = self.iconImage:getHeight()
		end

		self.height = math.max(textHeight, iconHeight) + 20
	end
end

function Button:setFont(font)
	self.font = font
end

function Button:setEnabled(isEnabled)
	self.isEnabled = isEnabled
	self:refreshIconImage()
end

function Button:refreshIconImage()
    if (not self.iconImagePath) then
        return
    end

	if (self.iconImageData) then
		self.iconImageData:release()
		self.iconImageData = nil
	end

	-- Make the image grayscale when disabled
	if (self.isEnabled) then
		self.iconImage = ImageCache:get(self.iconImagePath)
	else
		self.iconImageData = love.image.newImageData(self.iconImagePath)
		self.iconImageData:mapPixel(function(x, y, r, g, b, a)
			local gray = (r + g + b) / 3
			return gray, gray, gray, a
		end)
		self.iconImage = love.graphics.newImage(self.iconImageData)
	end
end

function Button:performUpdate(deltaTime)
	if (not self.isEnabled) then
		return
	end

    -- Don't allow clicking on the button if the player is blocked from input
	if (CurrentPlayer:isInputBlocked()) then
		return
	end

	self.isHovered = self:isPointerWithin()
	local isDown = love.mouse.isDown(1)

	if (self.isHovered) then
		CurrentPlayer:setWorldInputBlockedBy(self)
	elseif (CurrentPlayer:getWorldInputBlocker() == self) then
		CurrentPlayer:setWorldInputBlockedBy(nil)
	end

	if (not love.mouse.isCursorSupported()) then
		if (isDown) then
			TryCallIfNotOnCooldown(COMMON_COOLDOWNS.POINTER_INPUT, Times.clickInterval, function()
				self:onClick()
			end)
		end
	else
		-- When we release the mouse button, call the onClick function
		if (self.isHovered and self.isPressed and not isDown) then
			TryCallIfNotOnCooldown(COMMON_COOLDOWNS.POINTER_INPUT, Times.clickInterval, function()
				self.hasBeenNotPressedWithin = false
                self.isPressed = false

				-- Prevent the button from staying a blocker, even if the onclick has removed it/hidden it.
                if (CurrentPlayer:getWorldInputBlocker() == self) then
                    CurrentPlayer:setWorldInputBlockedBy(nil)
                end

				self:onClick()
			end)
		elseif (self.isHovered and not isDown) then
			self.hasBeenNotPressedWithin = true
		elseif (self.hasBeenNotPressedWithin and isDown) then
			self.isPressed = self.isHovered
		else
			self.hasBeenNotPressedWithin = false
			self.isPressed = false
		end
	end
end

function Button:performDraw(x, y, width, height)
	x, y = self:getPosition()

	if (not self.isWithoutBackground) then
		if self.isPressed then
			love.graphics.setColor(Colors.secondary())
		else
			if self.isHovered then
				love.graphics.setColor(Colors.primaryBright())
            else
				if (self.isEnabled) then
					love.graphics.setColor(Colors.primary())
				else
					love.graphics.setColor(Colors.primaryDisabled())
				end
			end
		end

		love.graphics.rectangle('fill', x, y, width, height)
	end

	if (self.iconImage) then
		if self.isPressed then
			love.graphics.setColor(0.8, 0.8, 0.8)
		else
			love.graphics.setColor(1, 1, 1)
		end

		if self.isHovered then
			-- Draw the icon slightly larger when hovered (offset it negatively by the hover amount)
			local hoverScale = 1.1
			local hoverOffset = (hoverScale - 1) * 0.5
			love.graphics.draw(self.iconImage, x - (width * hoverOffset), y - (height * hoverOffset),
				0, width * hoverScale / self.iconImage:getWidth(), height * hoverScale / self.iconImage:getHeight())
		else
			love.graphics.draw(self.iconImage, x, y, 0, width / self.iconImage:getWidth(),
				height / self.iconImage:getHeight())
		end
	end

	local textWidth = 0
	local textHeight = 0

	if (self.text) then
		if (self.font) then
			love.graphics.setFontSavingOld(self.font)

			local wrappedText
			textWidth, wrappedText = self.font:getWrap(self.text, width)
			textHeight = self.font:getHeight() * #wrappedText
		end

		love.graphics.setColor(1, 1, 1)
		love.graphics.printf(
			{
				Colors.text('table'),
				self.text
			},
			x,
			y + (height * .5) - (textHeight * .5),
			width,
			'center')


		if (self.font) then
			love.graphics.restoreFont()
		end
	end
end

return Button
