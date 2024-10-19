local Fonts = {}

--- Initializes the fonts, since we can't call love.graphics.* directly in the global scope,
--- due to us creating the window later in main.lua.
function Fonts:registerFonts()
	local defaultTiny = love.graphics.newFont('assets/fonts/Spectral-Regular.ttf', 12)
	local defaultMedium = love.graphics.newFont('assets/fonts/Spectral-Regular.ttf', 16)

	local boldSmall = love.graphics.newFont('assets/fonts/Spectral-ExtraBold.ttf', 12)
	local boldMedium = love.graphics.newFont('assets/fonts/Spectral-ExtraBold.ttf', 16)
	boldMedium:setLineHeight(0.75)
	local boldLarge = love.graphics.newFont('assets/fonts/Spectral-ExtraBold.ttf', 20)
	boldLarge:setLineHeight(0.75)
	local boldHuge = love.graphics.newFont('assets/fonts/Spectral-ExtraBold.ttf', 24)
	local boldMassive = love.graphics.newFont('assets/fonts/Spectral-ExtraBold.ttf', 32)

	Fonts.default = defaultMedium
	Fonts.buttonText = boldMedium
	Fonts.debug = defaultTiny

	Fonts.hint = defaultMedium
end

return Fonts
