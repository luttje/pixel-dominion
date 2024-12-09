require('init')

--- The current human player that is interacting with menus and the world.
--- @type PlayerHuman
CurrentPlayer = nil

--- Computer players that are controlled by AI.
--- @type PlayerComputer[]
local computerPlayers = {}

--- @type World
local currentWorld

--- Stagger unit commands so pathfinding doesn't get overwhelmed on certain frames.
--- @type Stagger
CommandStagger = Stagger({
	maxPerSecond = 50, -- TODO: Find a good number for this
})

function love.load()
    love.window.setIcon(love.image.newImageData('assets/images/game-icon-24.png'))

    local config = {}
	config.minwidth = 320
	config.minheight = 320

	if (love.system.getOS() == 'Web') then
		-- Full-screen mode will ensure the mouse input matches 1:1 in browser full-screen mode (if the console isn't opened)
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

	RequireDirectory('resources', function(fileWithoutExtension, module)
		local id = module.id or fileWithoutExtension

		ResourceTypeRegistry:registerResourceType(id, module)
	end)

	RequireDirectory('structures', function(fileWithoutExtension, module)
		local id = module.id or fileWithoutExtension

		StructureTypeRegistry:registerStructureType(id, module)
	end)

	-- TODO: Eventually we'll want to be able to load/restore player data, for now we just create a new player.
    CurrentPlayer = PlayerHuman({
		name = 'human player'
	})

	-- TODO: Currently hard-coded, just for testing our systems
    local playerFaction = Faction({
		factionType = FactionTypeRegistry:getFactionType('homelanders'),
        player = CurrentPlayer,
		color = Colors.factionColors[1]('table'),
    })

	currentWorld = World({
		mapPath = 'assets/worlds/forest_8x8.lua'
    })
    currentWorld:spawnFaction(playerFaction)
	currentWorld:addFogOfWarFaction(playerFaction)

    local numEnemyPlayers = 2

	local enemyPlayerFactions = {
		'barbarians',
		'emperials',
		'horsemasters',
		'warlords',
	}

	-- For future reference:
	assert(numEnemyPlayers <= 6, "Cannot have more than 6 enemy players since there's only that many spawn point markers.")
	assert(numEnemyPlayers <= #Colors.factionColors, "Cannot have more than " .. #Colors.factionColors .. " enemy players since there's only that many faction colors.")
	assert(numEnemyPlayers <= #enemyPlayerFactions, "Cannot have more than " .. #enemyPlayerFactions .. " enemy players since there's only that many factions.")

	for i = 1, numEnemyPlayers do
		local enemyPlayer = PlayerComputer({
			name = 'enemy player #' .. i,
		})
		table.insert(computerPlayers, enemyPlayer)
		local enemyFaction = Faction({
			factionType = FactionTypeRegistry:getFactionType(enemyPlayerFactions[i]),
            player = enemyPlayer,
			color = Colors.factionColors[i + 1]('table'),
		})
		currentWorld:spawnFaction(enemyFaction)
	end

    -- Add a barracks for testing
    playerFaction:spawnStructure(
		StructureTypeRegistry:getStructureType('barracks'),
        26,
		16,
		nil,
		FORCE_FREE_PLACEMENT
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

    -- Have all the computer players think
	for _, computerPlayer in ipairs(computerPlayers) do
		computerPlayer:update(deltaTime)
	end

	CommandStagger:update(deltaTime)
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
                local resource = currentWorld:findNearestResourceInstanceForFaction(playerFaction, resourceType, villager.x, villager.y)

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
            -- Spawn a villager for the enemy factions
            for _, computerPlayer in ipairs(computerPlayers) do
                local faction = computerPlayer:getFaction()
                local townHall = faction:getTownHall()
                townHall:generateUnit('villager')
            end
        elseif (key == 'f8') then
			--- TODO: I think we won't allow free zooming in the final game, but during development it's nice to have
            GameConfig.worldMapCameraScale = math.min(4, GameConfig.worldMapCameraScale + 1)
            print('World map camera scale increased to ' .. GameConfig.worldMapCameraScale)
        elseif (key == 'f9') then
			GameConfig.worldMapCameraScale = math.max(1, GameConfig.worldMapCameraScale - 1)
            print('World map camera scale decreased to ' .. GameConfig.worldMapCameraScale)
        elseif (key == 'f10') then
			GameConfig.gameSpeed = 1
			print('Game speed reset to ' .. GameConfig.gameSpeed)
        elseif (key == 'f11') then
			GameConfig.gameSpeed = math.min(8192, GameConfig.gameSpeed * 2) -- Any higher seems to not work
            print('Game speed increased to ' .. GameConfig.gameSpeed)
        elseif (key == 'f12') then
            -- If control is also held, special debug action
            if (love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')) then
				-- -- Remove all enemy structures
				-- for _, computerPlayer in ipairs(computerPlayers) do
				-- 	local faction = computerPlayer:getFaction()

				-- 	for _, structure in ipairs(faction:getStructures()) do
				-- 		structure:remove()
				-- 	end
                -- end

				-- Discover all the map
				currentWorld:revealMapForFaction(playerFaction)
			else
				-- Dump information about the computer players
				for _, computerPlayer in ipairs(computerPlayers) do
					computerPlayer:debugDirectiveList()
				end
			end
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
