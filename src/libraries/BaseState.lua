--- @class BaseState
---
--- @field name string
--- @field hasInitialized boolean
---
local BaseState = DeclareClass('BaseState')

local USE_MOUSE_AS_TOUCH = true
local TOUCH_SCROLL_FACTOR = 50
local TOUCH_SCROLL_FALL_OFF = 0.9

--- Creates a new BaseState.
--- @param config? table
function BaseState:initialize(config)
	self.hasInitialized = false
end

function BaseState:onStateInitialize(...)
	self.hasInitialized = true

	local fragmentContainer = InterfaceFragmentContainer()
	self.fragmentContainer = fragmentContainer

	if (self.onSetupInterface) then
        local windowWidth, windowHeight = love.graphics.getDimensions()

		self:onSetupInterface(fragmentContainer, windowWidth, windowHeight, ...)
	end

    return self
end

function BaseState:onExit()
	--
end

-- Update function to handle scrolling
function BaseState:updateScroll(deltaTime)
    if (not self.canScroll) then
		return
	end

    local windowWidth = love.graphics.getWidth()
    local maxScroll = self.totalWidth - windowWidth

	if (maxScroll < 0) then
		-- No need to scroll
		return
	end

	local scrollDelta = 0
	local touches = love.touch.getTouches()
	local firstTouch = touches[1]

    if (firstTouch or (USE_MOUSE_AS_TOUCH and love.mouse.isDown(1))) then
        local x, y

        if (USE_MOUSE_AS_TOUCH) then
            x, y = love.mouse.getPosition()
        else
            x, y = love.touch.getPosition(firstTouch)
        end

        if self.lastTouchX == 0 then
            self.lastTouchX = x
            self.lastTouchTime = love.timer.getTime()
        else
            local touchDelta = self.lastTouchX - x
            local timeDelta = love.timer.getTime() - self.lastTouchTime

            -- Calculate velocity based on distance and time
            local velocity = touchDelta / timeDelta

            -- Apply some smoothing to the velocity
            self.currentVelocity = self.currentVelocity * 0.8 + velocity * 0.2


            scrollDelta = self.currentVelocity * TOUCH_SCROLL_FACTOR * deltaTime

            self.lastTouchX = x
            self.lastTouchTime = love.timer.getTime()
        end
    elseif (not USE_MOUSE_AS_TOUCH) then
        local windowScrollBuffer = windowWidth * 0.1

        -- If left is pressed or the mouse is over the left side of the screen, scroll left
        if (love.keyboard.isDown('left') or love.mouse.getX() < windowScrollBuffer) then
            scrollDelta = -1 * self.scrollSpeed
        elseif (love.keyboard.isDown('right') or love.mouse.getX() > windowWidth - windowScrollBuffer) then
            scrollDelta = 1 * self.scrollSpeed
        end

        self.lastTouchX = 0
        self.currentVelocity = 0
    end

    if (scrollDelta == 0 and self.currentVelocity ~= 0) then
        -- Apply deceleration when no input is detected
        scrollDelta = self.currentVelocity * TOUCH_SCROLL_FACTOR * deltaTime
        self.currentVelocity = self.currentVelocity * TOUCH_SCROLL_FALL_OFF
        if math.abs(self.currentVelocity) < 1 then
            self.currentVelocity = 0
        end
    end

	self.scrollPosition = math.min(maxScroll, math.max(0, self.scrollPosition + scrollDelta * deltaTime))

    if (scrollDelta == 0) then
		-- No scroll was made
		return
    end

	-- -- Update card positions based on scroll, but only for cards not on the board
	-- local cardInDeckCount = 1
    -- for _, card in ipairs(self.cards) do
    --     if (card:isTiedToState(self)) then
	-- 		local x = (cardInDeckCount - 1) * (self.cardWidth + self.cardSpacing) - self.scrollPosition
	-- 		card:setPosition(x, card.originalY, true)
	-- 		cardInDeckCount = cardInDeckCount + 1
	-- 	end
    -- end
end

function BaseState:onUpdate(deltaTime)
    self.fragmentContainer:update(deltaTime)

	self:updateScroll(deltaTime)
end

function BaseState:onDraw(windowWidth, windowHeight)
	love.graphics.setColor(1, 1, 1)

	self.fragmentContainer:draw()
end

function BaseState:call(methodName, ...)
	if (self[methodName]) then
		return self[methodName](self, ...)
	end
end

return BaseState
