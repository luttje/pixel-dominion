--- Represents a section of the interface that can be updated and drawn
--- at a specific location on the screen.
--- @class InterfaceFragment
---
--- @field x? number If set this is the absolute x position of the fragment (for responsiveness use anchorHorizontally)
--- @field y? number If set this is the absolute y position of the fragment (for responsiveness use anchorVertically)
--- @field width? number|string If set this is the absolute width of the fragment (for responsiveness use anchorHorizontally), can be a string ending in '%' to be a percentage of the parent's width
--- @field height? number|string If set this is the absolute height of the fragment (for responsiveness use anchorVertically), can be a percentage like width
--- @field maxWidth? number|string Can be set to clamp the width of the fragment, can be a percentage like width.
--- @field maxHeight? number|string Can be set to clamp the height of the fragment, can be a percentage like height.
--- @field minWidth? number|string Can be set to clamp the width of the fragment, can be a percentage like width
--- @field minHeight? number|string Can be set to clamp the height of the fragment, can be a percentage like height
---
--- @field isVisible boolean
--- @field isClippingDisabled boolean
--- @field isDestroyed boolean
---
--- @field events EventManager
---
--- @field childFragments InterfaceFragmentContainer Contains the children of the fragment
--- @field parentContainer InterfaceFragmentContainer The parent container this fragment is in
---
--- @field performUpdate fun(self: InterfaceFragment, deltaTime: number)
--- @field performDraw fun(self: InterfaceFragment, x: number, y: number, width: number, height: number)
---
--- @field alignHorizontally 'start' | 'center' | 'end' # How the element aligns itself on its position (e.g: center will ensure half of the element will be to the left of x and half to the right)
--- @field alignVertically 'start' | 'center' | 'end' # How the element aligns itself on its position (e.g: center will ensure half of the element will be to the top of y and half to the bottom)
---
--- @field anchorHorizontally 'start' | 'center' | 'end' | 'fill' # How the element positions itself in its parent (e.g: end will ensure the element's right side is touching the parent's right side)
--- @field anchorVertically 'start' | 'center' | 'end' | 'fill' # How the element positions itself in its parent (e.g: end will ensure the element's bottom side is touching the parent's bottom side)
--- @field anchorMargins table # The margin between the element and its parent (can be a number which will be used for all sides or a table with top, right, bottom, left)
---
local InterfaceFragment = DeclareClass('InterfaceFragment')

--- Creates a new InterfaceFragment.
--- @param config? table
function InterfaceFragment:initialize(config)
	config = config or {}

	self.events = EventManager({
		target = self
	})

	self.isVisible = true
	self.isClippingDisabled = false

	-- Easily apply the same margin to all sides
	if (config.anchorMargins and type(config.anchorMargins) == 'number') then
		config.anchorMargins = {
			top = config.anchorMargins,
			right = config.anchorMargins,
			bottom = config.anchorMargins,
			left = config.anchorMargins
        }
	elseif (not config.anchorMargins) then
		config.anchorMargins = {}
	end

	self.childFragments = InterfaceFragmentContainer({
		ownerFragment = self
	})

	table.Merge(self, config)
end

--- Updates the InterfaceFragment.
--- @param deltaTime number
function InterfaceFragment:update(deltaTime)
	-- Override the performUpdate method in your InterfaceFragment implementation
	if (self.performUpdate) then
		self:performUpdate(deltaTime)
	end

	self.childFragments:update(deltaTime)
end

--- Draws the InterfaceFragment.
function InterfaceFragment:draw()
	if (self.isVisible) then
		local x, y = self:getPosition()
        local width, height = self:getSize()

		self:handleBoundsChangedEvent(x, y, width, height)

		-- Override the performDraw method in your InterfaceFragment implementation
		if (self.performDraw) then
			if (self.isClippingDisabled) then
				local screenWidth, screenHeight = love.graphics.getDimensions()
				love.graphics.setScissorSavingOld(0, 0, screenWidth, screenHeight)
			else
				love.graphics.setScissorSavingOld(x, y, width, height, true)
			end

			self.events:trigger('onPreDraw', {
				x = x,
				y = y,
				width = width,
				height = height
			})

			-- Determine any offset caused by the transformation with love.graphics.translate
			-- that may have been pushed in onPreDraw
			local coordinateOffsetX, coordinateOffsetY = love.graphics.transformPoint(0, 0)
			self.lastCoordinateOffset = { x = coordinateOffsetX, y = coordinateOffsetY }

			self:performDraw(x, y, width, height)

			self.events:trigger('onPostDraw', {
				x = x,
				y = y,
				width = width,
				height = height
			})

			love.graphics.restoreScissor()
		end

        if (self.isClippingDisabled) then
			local screenWidth, screenHeight = love.graphics.getDimensions()
			love.graphics.setScissorSavingOld(0, 0, screenWidth, screenHeight)
		else
            love.graphics.setScissorSavingOld(x, y, width, height)
        end

        self.childFragments:draw()

		love.graphics.restoreScissor()
	end
end

--- Changes the visibility of the InterfaceFragment.
--- @param isVisible boolean
function InterfaceFragment:setVisible(isVisible)
	self.isVisible = isVisible
end

--- Sets the clipping state for this fragment. If disabled with true, the fragment can draw outside of its bounds.
--- @param isClippingDisabled boolean
function InterfaceFragment:setClippingDisabled(isClippingDisabled)
	self.isClippingDisabled = isClippingDisabled
end

--- Sets the parent container of the InterfaceFragment.
--- @param parentContainer InterfaceFragmentContainer
function InterfaceFragment:setParentContainer(parentContainer)
	if (self.parentContainer) then
		-- Remove the fragment from its current parent container
		self.parentContainer:remove(fragment)
	end

	self.parentContainer = parentContainer

	local parentEventManager

	-- Feels a bit dirty
	-- TODO: Should probably be a method on the InterfaceFragmentContainer
	if (parentContainer and parentContainer.ownerFragment) then
		parentEventManager = parentContainer.ownerFragment.events
	end

	self.events.bubbleTo = parentEventManager
end

--- TODO: Cache this until the size changes, since it's a bit expensive
--- @return number
function InterfaceFragment:getX()
	local x = self.x
	local width = self:getWidth()

	local parentX, parentWidth

	if (self.parentContainer and self.parentContainer.ownerFragment) then
		parentX = self.parentContainer.ownerFragment:getX()
		parentWidth = self.parentContainer.ownerFragment:getWidth()
	else
		parentX = 0
		parentWidth = love.graphics.getWidth()
	end

	if (self.anchorHorizontally) then
		assert(not self.x, 'Cannot use both x and anchorHorizontally')

		if (self.anchorHorizontally == 'start' or self.anchorHorizontally == 'fill') then
			x = parentX + (self.anchorMargins and self.anchorMargins.left or 0)
		elseif (self.anchorHorizontally == 'center') then
			x = parentX + (parentWidth * .5)
		elseif (self.anchorHorizontally == 'end') then
			x = parentX + parentWidth - (self.anchorMargins and self.anchorMargins.right or 0)
		else
			error('Invalid anchorHorizontally value: ' .. self.anchorHorizontally)
		end
	end

	-- Normally: left, center, right
	-- TODO: In the future we could support RTL languages
	if (not self.alignHorizontally) then
		-- Do nothing
	elseif (self.alignHorizontally == 'start') then
		-- Do nothing
	elseif (self.alignHorizontally == 'center') then
		x = x - (width * .5)
	elseif (self.alignHorizontally == 'end') then
		x = x - width
	else
		error('Invalid alignHorizontally value: ' .. self.alignHorizontally)
	end

	return x
end

--- TODO: Cache this until the size changes, since it's a bit expensive
--- @return number
function InterfaceFragment:getY()
	local y = self.y
	local height = self:getHeight()

	local parentY, parentHeight

	if (self.parentContainer and self.parentContainer.ownerFragment) then
		parentY = self.parentContainer.ownerFragment:getY()
		parentHeight = self.parentContainer.ownerFragment:getHeight()
	else
		parentY = 0
		parentHeight = love.graphics.getHeight()
	end

	if (self.anchorVertically) then
		assert(not self.y, 'Cannot use both y and anchorVertically')

		if (self.anchorVertically == 'start' or self.anchorVertically == 'fill') then
			y = parentY + (self.anchorMargins and self.anchorMargins.top or 0)
		elseif (self.anchorVertically == 'center') then
			y = parentY + (parentHeight * .5)
		elseif (self.anchorVertically == 'end') then
			y = parentY + parentHeight - (self.anchorMargins and self.anchorMargins.bottom or 0)
		else
			error('Invalid anchorVertically value: ' .. self.anchorVertically)
		end
	end

	if (not self.alignVertically) then
		-- Do nothing
	elseif (self.alignVertically == 'start') then
		-- Do nothing
	elseif (self.alignVertically == 'center') then
		y = y - (height * .5)
	elseif (self.alignVertically == 'end') then
		y = y - height
	else
		error('Invalid alignVertically value: ' .. self.alignVertically)
	end

	return y
end

--- Gets the position of the InterfaceFragment.
--- Child classes can override this if they do special positioning (e.g: centering)
--- @return number, number
function InterfaceFragment:getPosition()
	return self:getX(), self:getY()
end

--- Transforms the given point, relative to the last known offset position.
--- Useful when fragments are pushed into a different coordinate system.
--- @param x number
--- @param y number
--- @return number, number
function InterfaceFragment:transformPoint(x, y)
	if (self.lastCoordinateOffset) then
		x = x + self.lastCoordinateOffset.x
		y = y + self.lastCoordinateOffset.y
	end

	return x, y
end

--- Returns the width of the InterfaceFragment.
--- TODO: Cache this until the size changes, since it's a bit expensive
--- @return number
function InterfaceFragment:getWidth()
	local width = self.width

	local parentWidth

	if (self.parentContainer and self.parentContainer.ownerFragment) then
        parentWidth = self.parentContainer.ownerFragment:getWidth()
	else
		parentWidth = love.graphics.getWidth()
	end

	if (self.anchorHorizontally == 'fill') then
		width = parentWidth - (self.anchorMargins and self.anchorMargins.left or 0) -
			(self.anchorMargins and self.anchorMargins.right or 0)
	end

	width = math.ParsePercentage(width, parentWidth)

	assert(width, 'Invalid width value: ' .. tostring(self.width) .. ' (in ' .. type(self) .. ')')

	if (self.maxWidth) then
		local maxWidth = math.ParsePercentage(self.maxWidth, parentWidth)
		width = math.min(width, maxWidth)
	end

	if (self.minWidth) then
		local minWidth = math.ParsePercentage(self.minWidth, parentWidth)
		width = math.max(width, minWidth)
	end

	if (self.isClippingDisabled) then
		return math.max(0, width)
	end

	-- Scale down with parent if it's smaller
	return math.max(0, math.min(width, parentWidth))
end

--- TODO: Cache this until the size changes, since it's a bit expensive
--- Returns the height of the InterfaceFragment.
--- @return number
function InterfaceFragment:getHeight()
	local height = self.height

	local parentHeight

    if (self.parentContainer and self.parentContainer.ownerFragment) then
        parentHeight = self.parentContainer.ownerFragment:getHeight()
    else
        parentHeight = love.graphics.getHeight()
    end

	if (self.anchorVertically == 'fill') then
		height = parentHeight - (self.anchorMargins and self.anchorMargins.top or 0) -
			(self.anchorMargins and self.anchorMargins.bottom or 0)
	end

	-- If the height is a percentage, calculate it based on the parent's size
	height = math.ParsePercentage(height, parentHeight)

	if (self.maxHeight) then
		local maxHeight = math.ParsePercentage(self.maxHeight, parentHeight)
        height = math.min(height, maxHeight)
	end

	if (self.minHeight) then
		local minHeight = math.ParsePercentage(self.minHeight, parentHeight)
		height = math.max(height, minHeight)
	end

	assert(height, 'Invalid height value: ' .. tostring(self.height) .. ' (in ' .. type(self) .. ')')

	if (self.isClippingDisabled) then
		return math.max(0, height)
	end

	-- Scale down with parent if it's smaller
	return math.max(0, math.min(height, parentHeight))
end

--- Gets the width and height of the InterfaceFragment.
--- This respects the anchorHorizontally and anchorVertically properties.
--- @return number, number
function InterfaceFragment:getSize()
	return self:getWidth(), self:getHeight()
end

--- Sets the position of the InterfaceFragment.
--- Will fail if the fragment is anchored to its parent.
--- @param x? number
--- @param y? number
function InterfaceFragment:setPosition(x, y)
	self:setX(x, true)
	self:setY(y, true)

	self:handleBoundsChangedEvent()
end

--- Sets the size of the InterfaceFragment.
--- Will fail if the fragment is anchored to its parent with fill.
--- @param width? number
--- @param height? number
function InterfaceFragment:setSize(width, height)
	self:setWidth(width, true)
	self:setHeight(height, true)

	self:handleBoundsChangedEvent()
end

--- Sets the X position of the InterfaceFragment.
--- Will fail if the fragment is anchored to its parent.
--- @param x number
--- @param dontTriggerEvent? boolean
function InterfaceFragment:setX(x, dontTriggerEvent)
	assert(x == nil or not self.anchorHorizontally,
		'Cannot set position of InterfaceFragment that is anchored horizontally')

	self.x = x

	if (not dontTriggerEvent) then
		self:handleBoundsChangedEvent()
	end
end

--- Sets the Y position of the InterfaceFragment.
--- Will fail if the fragment is anchored to its parent.
--- @param y number
--- @param dontTriggerEvent? boolean
function InterfaceFragment:setY(y, dontTriggerEvent)
	assert(y == nil or not self.anchorVertically, 'Cannot set position of InterfaceFragment that is anchored vertically')

	self.y = y

	if (not dontTriggerEvent) then
		self:handleBoundsChangedEvent()
	end
end

--- Sets the width of the InterfaceFragment.
--- Will fail if the fragment is anchored to its parent with fill.
--- @param width number
--- @param dontTriggerEvent? boolean
function InterfaceFragment:setWidth(width, dontTriggerEvent)
	assert(width == nil or self.anchorHorizontally ~= 'fill',
		'Cannot set size of InterfaceFragment that is anchored horizontally')

	self.width = width

	if (not dontTriggerEvent) then
		self:handleBoundsChangedEvent()
	end
end

--- Sets the height of the InterfaceFragment.
--- Will fail if the fragment is anchored to its parent with fill.
--- @param height number
--- @param dontTriggerEvent? boolean
function InterfaceFragment:setHeight(height, dontTriggerEvent)
	assert(height == nil or self.anchorVertically ~= 'fill',
		'Cannot set size of InterfaceFragment that is anchored vertically')

	self.height = height

	if (not dontTriggerEvent) then
		self:handleBoundsChangedEvent()
	end
end

--- Checks if the InterfaceFragment changed its bounds and emits an event if it did.
--- If no parameters are provided it will use getPosition and getSize to get the current bounds.
--- @param x? number
--- @param y? number
--- @param width? number
--- @param height? number
function InterfaceFragment:handleBoundsChangedEvent(x, y, width, height)
	if (not x or not y) then
		local currentX, currentY = self:getPosition()
		x, y = x or currentX, y or currentY
	end

	if (not width or not height) then
		local currentWidth, currentHeight = self:getSize()
		width, height = width or currentWidth, height or currentHeight
	end

	if (
			not self._lastKnownPosition
			or self._lastKnownPosition.x ~= x
			or self._lastKnownPosition.y ~= y
			or self._lastKnownPosition.width ~= width
			or self._lastKnownPosition.height ~= height
		) then
		self.events:trigger('onBoundsChanged', {
			x = x,
			y = y,
			width = width,
			height = height
		})
		self._lastKnownPosition = {
			x = x,
			y = y,
			width = width,
			height = height
		}
	end
end

function InterfaceFragment:isPointerWithin()
	local x, y = self:transformPoint(self:getPosition())
	local width, height = self:getSize()

	local pointerX, pointerY = Input.GetPointerPosition()

	return pointerX >= x
		and pointerX <= x + width
		and pointerY >= y
		and pointerY <= y + height
end

function InterfaceFragment:getBoundsWithinRatio(x, y, width, height)
	local fragmentX, fragmentY = self:getPosition()
	local fragmentWidth, fragmentHeight = self:getSize()
	local fragmentX2, fragmentY2 = fragmentX + fragmentWidth, fragmentY + fragmentHeight
	local boundsX2, boundsY2 = x + width, y + height

	local x1 = math.max(fragmentX, x)
	local y1 = math.max(fragmentY, y)
	local x2 = math.min(fragmentX2, boundsX2)
	local y2 = math.min(fragmentY2, boundsY2)

	local intersectionArea = math.max(0, x2 - x1) * math.max(0, y2 - y1)
	local fragmentArea = fragmentWidth * fragmentHeight

	return intersectionArea / fragmentArea
end

--- Gets the visual center of the InterfaceFragment.
--- @return number, number
function InterfaceFragment:getVisualCenter()
	local x, y = self:getPosition()
	local width, height = self:getSize()
	return x + (width * .5), y + (height * .5)
end

--- Destroys the InterfaceFragment.
--- This will remove the fragment from its parent container.
function InterfaceFragment:destroy()
    self.isDestroyed = true

	if (self.parentContainer) then
		self.parentContainer:remove(self)
	end
end

return InterfaceFragment
