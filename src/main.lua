require('init')

function love.load()
    love.window.setIcon(love.image.newImageData('assets/images/game-icon-64.png'))

    local config = {}
	config.minwidth = 320
	config.minheight = 320

	if (love.system.getOS() == 'Web') then
		-- Full-screen mode will ensure the mouse input matches 1:1 in browser full-screen mode.
        config.fullscreen = true
    else
        -- config.display = 2 -- TODO: Make this configurable (just for testing on my machine)
		config.resizable = true
    end

    love.window.setMode(600, 920, config)

	love.graphics.setBackgroundColor(0, 0, 0)
	love.graphics.setDefaultFilter('nearest', 'nearest')

	Fonts:registerFonts()

	-- Now that the window is created we can initialize unit and resource graphics
	RequireDirectory('unit-types', function(fileWithoutExtension, module)
		local id = module.id or fileWithoutExtension

		UnitTypeRegistry:registerUnitType(id, module)
	end)

	Resources:registerResources()

	-- TODO: Eventually we'll want to be able to load/restore player data, for now we just create a new player.
	CurrentPlayer = Player()

	-- TODO: Currently hard-coded, just for testing our systems
    local playerFaction = Faction({
		factionType = FactionTypeRegistry:getFactionType('homelanders'),
    })

	playerFaction:spawnUnit(
        UnitTypeRegistry:getUnitType('builder'),
        16, 8
	)
	CurrentPlayer:setFaction(playerFaction)

	local world = World({
		mapPath = 'assets/worlds/forest_8x8.lua'
    })
	world:addFaction(playerFaction)
    CurrentPlayer:setWorld(world)

    StateManager:setCurrentState(InGameState)
end

function love.update(deltaTime)
	love.window.setTitle(GameConfig.name .. ' (FPS: ' .. love.timer.getFPS() .. ')')

	StateManager:call('onUpdate', deltaTime)

	Timer.updateAll(deltaTime)
end

function love.draw()
	local windowWidth, windowHeight = love.graphics.getDimensions()

	StateManager:call('onDraw', windowWidth, windowHeight)
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end

	StateManager:call('onKeyPressed', key)
end

function love.keyreleased(key)
	StateManager:call('onKeyReleased', key)
end

function love.mousemoved(x, y, dx, dy)
	StateManager:call('onInputMoved', x, y, dx, dy)
end

function love.mousepressed(x, y, button, isTouch, presses)
	StateManager:call('onInputDown', x, y, button, isTouch, presses)
end

function love.mousereleased(x, y, button, isTouch)
	StateManager:call('onInputReleased', x, y, button, isTouch)
end
