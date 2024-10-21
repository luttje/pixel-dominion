local InGameState = DeclareClassWithBase('InGameState', BaseState)

function InGameState:onStateInitialize(...)
	self:getBase():onStateInitialize(...)
end

function InGameState:onSetupInterface(fragments, windowWidth, windowHeight, ...)
	-- World map background
	self.worldMap = WorldMap({
		anchorHorizontally = 'fill',
		anchorVertically = 'fill',
		world = CurrentPlayer:getWorld()
	})
    fragments:add(self.worldMap)

    -- Resource bar
	local resourceBar = ResourceBar({
		anchorHorizontally = 'fill',
        anchorVertically = 'start',
		height = 48,
		world = CurrentPlayer:getWorld()
	})
	fragments:add(resourceBar)
end

function InGameState:onEnter()
	self.worldMap:refreshMap()
end

function InGameState:onUpdate(deltaTime)
	self:getBase():onUpdate(deltaTime)
end

function InGameState:onDraw(windowWidth, windowHeight)
	love.graphics.clear(0, 0, 0)
	love.graphics.setColor(1, 1, 1)

	self:getBase():onDraw(windowWidth, windowHeight)
end

return InGameState
