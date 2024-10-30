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

--- Draws progress circle that unwinds clockwise as the progress increases
--- @param x number The x-coordinate of the center of the circle
--- @param y number The y-coordinate of the center of the circle
--- @param radius number The radius of the circle
--- @param progress number The progress of the circle (0-1)
function love.graphics.drawProgressCircle(x, y, radius, progress)
	-- Validate progress value to ensure it's between 0 and 1
	progress = math.max(0, math.min(1, progress))

	-- Save the current graphics state
	love.graphics.push()

	-- Move to the center point
	love.graphics.translate(x, y)

	-- Draw the background circle
	love.graphics.setColor(0.2, 0.2, 0.2, 0.3)
	love.graphics.circle('fill', 0, 0, radius)

	-- Calculate the start and end angles
	local startAngle = -math.pi / 2 -- Start at 12 o'clock position
	local endAngle = startAngle + (2 * math.pi * progress)

	-- Number of segments to use for the arc
	local segments = 64

	-- Calculate points for the arc
	local points = {}

	-- Always add center point as first point
	table.insert(points, 0)
	table.insert(points, 0)

	-- Calculate intermediate points
	for i = 0, segments do
		local angle = startAngle + (i / segments) * (endAngle - startAngle)
		if angle > endAngle then break end

		local px = math.cos(angle) * radius
		local py = math.sin(angle) * radius

		table.insert(points, px)
		table.insert(points, py)
	end

	-- Draw the progress arc
	love.graphics.setColor(1, 1, 1, 0.6)

	-- Only draw if we have at least 3 points (center + 2 points)
	if (#points > 4) then
		love.graphics.polygon('fill', points)
	end

	-- Restore the graphics state
	love.graphics.pop()
end

--- Draws a rounded rectangle
--- Source: https://gist.github.com/gvx/9072860
function love.graphics.roundRect(mode, x, y, width, height, horizontalRoundingOrBoth, verticalRounding)
	verticalRounding = verticalRounding or horizontalRoundingOrBoth

	assert(horizontalRoundingOrBoth >= 0, 'horizontalRoundingOrBoth must be greater than or equal to 0')
	assert(verticalRounding >= 0, 'verticalRounding must be greater than or equal to 0')

	if (horizontalRoundingOrBoth == 0 and verticalRounding == 0) then
		love.graphics.rectangle(mode, x, y, width, height)
		return
	end

	assert(horizontalRoundingOrBoth > 10 and verticalRounding > 10, 'love.graphics.roundRect works best with rounding values greater than 10')


	local points = {}
	local precision = (horizontalRoundingOrBoth + verticalRounding) * .1
	local halfPi = math.pi * .5

	if horizontalRoundingOrBoth > width * .5 then
		horizontalRoundingOrBoth = width * .5
	end

	if verticalRounding > height * .5 then
		verticalRounding = height * .5
	end

	local X1, Y1, X2, Y2 = x + horizontalRoundingOrBoth,
		y + verticalRounding,
		x + width - horizontalRoundingOrBoth,
		y + height - verticalRounding

	for i = 0, precision do
		local a = (i / precision - 1) * halfPi
		table.insert(points, X2 + horizontalRoundingOrBoth * math.cos(a))
		table.insert(points, Y1 + verticalRounding * math.sin(a))
	end

	for i = 0, precision do
		local a = (i / precision) * halfPi
		table.insert(points, X2 + horizontalRoundingOrBoth * math.cos(a))
		table.insert(points, Y2 + verticalRounding * math.sin(a))
	end

	for i = 0, precision do
		local a = (i / precision + 1) * halfPi
		table.insert(points, X1 + horizontalRoundingOrBoth * math.cos(a))
		table.insert(points, Y2 + verticalRounding * math.sin(a))
	end

	for i = 0, precision do
		local a = (i / precision + 2) * halfPi
		table.insert(points, X1 + horizontalRoundingOrBoth * math.cos(a))
		table.insert(points, Y1 + verticalRounding * math.sin(a))
	end

	love.graphics.polygon(mode, unpack(points))
end
