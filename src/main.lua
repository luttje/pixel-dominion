require('init')

--- @type World
local currentWorld

function love.load()
    love.window.setIcon(love.image.newImageData('assets/images/game-icon-64.png'))

    local config = {}
	config.minwidth = 320
	config.minheight = 320

	if (love.system.getOS() == 'Web') then
		-- Full-screen mode will ensure the mouse input matches 1:1 in browser full-screen mode.
        config.fullscreen = true
    else
        config.display = 2 -- TODO: Make this configurable (just for testing on my machine)
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

	RequireDirectory('resources', function(fileWithoutExtension, module)
		local id = module.id or fileWithoutExtension

		ResourceTypeRegistry:registerResourceType(id, module)
	end)

	RequireDirectory('structures', function(fileWithoutExtension, module)
		local id = module.id or fileWithoutExtension

		StructureTypeRegistry:registerStructureType(id, module)
	end)

	-- TODO: Eventually we'll want to be able to load/restore player data, for now we just create a new player.
	CurrentPlayer = Player()

	-- TODO: Currently hard-coded, just for testing our systems
    local playerFaction = Faction({
		factionType = FactionTypeRegistry:getFactionType('homelanders'),
    })
    CurrentPlayer:setFaction(playerFaction)

	currentWorld = World({
		mapPath = 'assets/worlds/forest_8x8.lua'
    })
    CurrentPlayer:setWorld(currentWorld)
    currentWorld:spawnFaction(playerFaction)

	testEnemyFaction = Faction({
		factionType = FactionTypeRegistry:getFactionType('bandits'),
	})
	currentWorld:spawnFaction(testEnemyFaction)

    -- Add a barracks for testing
    playerFaction:spawnStructure(
		StructureTypeRegistry:getStructureType('barracks'),
		26, 16
	)
	-- TODO: End of hard-coded tests

    StateManager:setCurrentState(InGameState, currentWorld)

	if (not GameConfig.disableMusic) then
		-- TODO: Create music manager that will handle playing more intense music during battles
		Sounds.musicMain:play()
	end
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

	if (GameConfig.debugCheatsEnabled) then
		local playerFaction = CurrentPlayer:getFaction()
        if (key == 'f1') then
            -- Spawn a villager and if there's a barracks, spawn a warrior
            local townHall = playerFaction:getTownHall()
            townHall:generateUnit('villager')

            local barracks = playerFaction:getStructuresOfType('barracks')[1]
			if (barracks) then
				barracks:generateUnit('warrior')
			end
		elseif (key == 'f2') then
            -- Give 100 of each resource
            for _, resourceType in ipairs(ResourceTypeRegistry:getAllResourceTypes()) do
                playerFaction:getResourceInventory():add(resourceType, 100)
            end
        elseif (key == 'f3') then
            local villagerStack = table.Stack(table.ShallowCopy(playerFaction:getUnitsOfType('villager')))

            -- Send all villagers to go randomly harvest resources of any type
            while (not villagerStack:isEmpty()) do
                local villager = villagerStack:pop()
                local resourceType = ResourceTypeRegistry:getRandomResourceType(function(resourceType)
                    return resourceType:isHarvestable()
                end)
                local resource = currentWorld:findNearestResourceInstance(resourceType, villager.x, villager.y)

                if (resource) then
                    villager:commandTo(resource.x, resource.y, resource)
                else
                    print('No resource found for villager to harvest.', resourceType.id)
                end
            end
        elseif (key == 'f4') then
            -- Log information on the resources and their supply
            print('====================================')
            print('Resources:')

            for _, resourceType in ipairs(ResourceTypeRegistry:getAllResourceTypes()) do
				local resources = currentWorld:getResourceInstancesOfType(resourceType)

                print(resourceType.id .. ': ')

				for _, resource in ipairs(resources) do
					print('  - #' .. resource.id .. ': ' .. resource:getSupply())
				end
			end
		elseif (key == 'f5') then
			-- Log information on the units
			print('====================================')
			print('Units:')

			for _, unit in ipairs(playerFaction:getUnits()) do
				print('  - #' .. unit.id)
			end
		elseif (key == 'f6') then
			-- Log information on the structures
			print('====================================')
			print('Structures:')

			for _, structure in ipairs(playerFaction:getStructures()) do
				print('  - #' .. structure.id)
			end
        elseif (key == 'f7') then
            -- Spawn a villager for testEnemyFaction
            local townHall = testEnemyFaction:getTownHall()
            townHall:getStructureType():generateUnit(townHall)
        elseif (key == 'f11') then
            GameConfig.gameSpeed = math.min(1000, GameConfig.gameSpeed + 1)
            print('Game speed increased to ' .. GameConfig.gameSpeed)
		elseif (key == 'f12') then
            GameConfig.gameSpeed = math.max(0.1, GameConfig.gameSpeed - 1)
			print('Game speed decreased to ' .. GameConfig.gameSpeed)
		end
	end
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
