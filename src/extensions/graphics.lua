--- Draws a drawable, such that it covers the given area
--- @param drawable love.Drawable
--- @param x number Where to draw the drawable on the x-axis
--- @param y number Where to draw the drawable on the y-axis
--- @param areaWidth? number If not provided, will use the screen width
--- @param areaHeight? number If not provided, will use the screen height
--- @param alignX? 'start'|'center'|'end' Whether to align the drawable on the x-axis (default: 'start')
--- @param alignY? 'start'|'center'|'end' Whether to align the drawable on the y-axis (default: 'start')
--- @param shouldClip? boolean Whether to clip the drawable if it goes outside the area (default: true)
function love.graphics.drawCover(drawable, x, y, areaWidth, areaHeight, alignX, alignY, shouldClip)
    areaWidth = areaWidth or love.graphics.getWidth()
    areaHeight = areaHeight or love.graphics.getHeight()

    local width, height = drawable:getDimensions()
    local scale = math.max(areaWidth / width, areaHeight / height)

	local drawWidth = width * scale
	local drawHeight = height * scale

	alignX = alignX or 'start'
	alignY = alignY or 'start'
	shouldClip = shouldClip == nil or shouldClip

	local shouldCenterX = alignX == 'center'
	local shouldCenterY = alignY == 'center'

	if (shouldClip) then
		love.graphics.setScissorSavingOld(x, y, areaWidth, areaHeight)
	end

	-- Center the drawable inside the area (clipping it so it doesn't go outside)
	if (shouldCenterX or shouldCenterY) then
		local finalX = (areaWidth - drawWidth) * .5
		local finalY = (areaHeight - drawHeight) * .5

		if (shouldCenterX) then
			x = x + finalX
		end

		if (shouldCenterY) then
			y = y + finalY
		end
	end

	-- If we want to align the drawable to the end, we need to move it to the end of the area
	if (alignX == 'end') then
		x = x + areaWidth - drawWidth
	end

	if (alignY == 'end') then
		y = y + areaHeight - drawHeight
	end

    love.graphics.draw(drawable, x, y, 0, scale, scale)

    if (shouldClip) then
    	love.graphics.restoreScissor()
	end
end

--- Draws a drawable, such that it covers the given area by tiling it
--- @param drawable love.Drawable
--- @param x number Where to draw the drawable on the x-axis
--- @param y number Where to draw the drawable on the y-axis
--- @param areaWidth number The width of the area to cover
--- @param areaHeight number The height of the area to cover
--- @param tileWidth? number The width of the tile
--- @param tileHeight? number The height of the tile
function love.graphics.drawTiled(drawable, x, y, areaWidth, areaHeight, tileWidth, tileHeight)
	local width, height = drawable:getDimensions()

	tileWidth = tileWidth or width
	tileHeight = tileHeight or height

	for i = 0, math.ceil(areaWidth / tileWidth) do
		for j = 0, math.ceil(areaHeight / tileHeight) do
			love.graphics.draw(drawable, x + i * tileWidth, y + j * tileHeight)
		end
	end
end

--- Sets the font, saving the old font for easy restoration
--- @param font love.Font
function love.graphics.setFontSavingOld(font)
	love.graphics._oldFont = love.graphics.getFont()
	love.graphics.setFont(font)
end

--- Restores the old font
function love.graphics.restoreFont()
	assert(love.graphics._oldFont, 'No font to restore.')
	love.graphics.setFont(love.graphics._oldFont)
	love.graphics._oldFont = nil
end

local scissorStack = {}

--- Sets a scissor rectangle, saving the old scissor rectangle for easy restoration
--- @param x number The x-coordinate of the top-left corner of the rectangle
--- @param y number The y-coordinate of the top-left corner of the rectangle
--- @param width number The width of the rectangle
--- @param height number The height of the rectangle
--- @param shouldIntersect? boolean Whether to intersect the new scissor rectangle with the old one (default: false)
function love.graphics.setScissorSavingOld(x, y, width, height, shouldIntersect)
    table.insert(scissorStack, { love.graphics.getScissor() })
	shouldIntersect = shouldIntersect or false

	if (shouldIntersect) then
		love.graphics.intersectScissor(x, y, width, height)
	else
		love.graphics.setScissor(x, y, width, height)
	end
end

--- Restores the old scissor rectangle
function love.graphics.restoreScissor()
	local oldScissor = table.remove(scissorStack)
	assert(oldScissor, 'No scissor to restore.')
	love.graphics.setScissor(unpack(oldScissor))
end
