-- Original Source: https://github.com/karai17/Simple-Tiled-Implementation
-- Modified for our use case.
local Sti = require('third-party.sti')
local Grid = require('third-party.jumper.grid')
local Pathfinder = require('third-party.jumper.pathfinder')

WALKABLE = 0
NOT_WALKABLE = 1

--- Used to reduce memory usage by limiting the cache size
local PATH_CACHE_SIZE = 1000

--- Used to prevent paths that might not be valid anymore (e.g. due to structures being built)
local PATH_EXPIRATION_TIME = 10

--- Cache for the paths
local pathCache = table.CircularBufferWithLookup({}, PATH_CACHE_SIZE, function(path)
	return path.startX .. ',' .. path.startY .. '-' .. path.endX .. ',' .. path.endY
end)

--- Represents a world that contains factions
--- @class World
---
--- @field mapPath string # The path to the map file
---
--- @field factions Faction[] # The factions in the world
--- @field fogOfWarFactions table<Faction, boolean> # The factions that we are seeing through the fog of war for
---
--- @field resourceInstances Resource[] # The resource instances in the world
---
--- @field spawnPoints table<number, table<number, number>> # The spawn points for the factions
--- @field searchTree QuadTree # The search tree for the world
local World = DeclareClass('World')

--- Initializes the world
--- @param config table
function World:initialize(config)
	config = config or {}

	assert(config.mapPath, 'Map path is required.')

    self.factions = {}
    self.fogOfWarFactions = {}

	self.resourceInstances = {}
    self.spawnPoints = {}

	table.Merge(self, config)

	self:loadMap()
end

-- Load a map exported to Lua from Tiled
function World:loadMap()
    local mapPath = self.mapPath

	self.layerCallbacks = {}

	self.map = Sti(mapPath, { 'box2d' })

	-- Prepare physics world with horizontal and vertical gravity
	self.world = love.physics.newWorld(0, 0)

	-- Prepare collision objects
    self.map:box2d_init(self.world)

	-- Let us search for objects in the map quickly
	self.searchTree = QuadTree({
		boundary = {
			x = self.map.offsetx,
			y = self.map.offsety,
			width = self.map.width,
			height = self.map.height
        },
	})

	-- Call update and draw callbacks for these layers
	local layersWithCallbacks = {
		'Dynamic_Units',
		'Dynamic_Structures'
	}

	for _, layerName in ipairs(layersWithCallbacks) do
		local layer = self.map.layers[layerName]

		if (layer) then
			function layer.update(layer, dt)
				if (not self.layerCallbacks[layerName] or not self.layerCallbacks[layerName].update) then
					return
				end

				for _, callback in ipairs(self.layerCallbacks[layerName].update) do
					callback(dt)
				end
			end

			function layer.draw(layer)
				if (not self.layerCallbacks[layerName] or not self.layerCallbacks[layerName].draw) then
					return
				end

				for _, callback in ipairs(self.layerCallbacks[layerName].draw) do
					callback()
				end
			end
		end
	end

	-- Find all spawnpoints (GameConfig.factionSpawnTileIds)
	for _, layer in ipairs(self.map.layers) do
		if (layer.data) then
			for y = 1, self.map.height do
				for x = 1, self.map.width do
					local tile = layer.data[y][x]

					for _, spawnTile in ipairs(GameConfig.factionSpawnTileIds) do
						if (tile and tile.id == spawnTile.tileId and tile.tileset == spawnTile.tilesetId) then
							table.insert(self.spawnPoints, { x = x - 1, y = y - 1 })
						end
					end
				end
			end
		end
	end

	-- Cache the static collision map
	self:updateCollisionMap()

    -- Go through all resource types and check all layers for a match of spawnAtTileId
    local map = self.map

	for _, resourceType in ipairs(ResourceTypeRegistry:getAllResourceTypes()) do
		for __, layer in ipairs(map.layers) do
			if (layer.data) then
				for y = 1, map.height do
					for x = 1, map.width do
						local tile = layer.data[y][x]

                        if (tile and tile.id == resourceType.spawnAtTileId) then
							self:addResourceInstance(
								resourceType:spawnAtTile(self, x - 1, y - 1)
							)
						end
					end
				end
			end
		end
	end

    if (GameConfig.mapLayersToRemove) then
        for _, layerName in ipairs(GameConfig.mapLayersToRemove) do
            self.map:removeLayer(layerName)
        end
    end

    self:registerLayerCallback('Dynamic_Units', 'draw', function()
		for _, faction in ipairs(self.factions) do
			for _, unit in ipairs(faction:getUnits()) do
				unit:draw()
			end
		end
	end)

	self:registerLayerCallback('Dynamic_Units', 'update', function(deltaTime)
		for _, faction in ipairs(self.factions) do
			for _, unit in ipairs(faction:getUnits()) do
				unit:update(deltaTime)
			end
		end
	end)
end

--- Registers a callback for a specific layer and callback type.
--- @param layerName string
--- @param callbackType 'update' | 'draw'
--- @param callback function
function World:registerLayerCallback(layerName, callbackType, callback)
	if (not self.map) then
		assert(false, 'No map loaded.')
		return
	end

	if (not self.layerCallbacks[layerName]) then
		self.layerCallbacks[layerName] = {}
	end

	if (not self.layerCallbacks[layerName][callbackType]) then
		self.layerCallbacks[layerName][callbackType] = {}
	end

	table.insert(self.layerCallbacks[layerName][callbackType], callback)
end

function World:update(deltaTime)
	if (not self.map) then
		assert(false, 'No map loaded.')
		return
	end

	self.map:update(deltaTime)

    -- Update all factions
	for _, faction in ipairs(self.factions) do
		faction:update(deltaTime)
	end
end

function World:draw(translateX, translateY, scaleX, scaleY)
	if (not self.map) then
		assert(false, 'No map loaded.')
		return
	end

	-- Draw the map and all objects within
	love.graphics.setColor(1, 1, 1)
	self.map:draw(translateX, translateY, scaleX, scaleY)

    if (GameConfig.debugCollisionMap) then
        love.graphics.setColor(1, 0, 0)
        self.map:box2d_draw(translateX, translateY, scaleX, scaleY)
    end
end

--- Returns the collision map for the loaded map based on the 'collidable' property of the layers.
--- Additionally it returns the number representing
--- @return table<number, table<number, number>>
function World:updateCollisionMap()
	-- Regular collision map, where we can and can't walk
    local collisionMap = {}

	-- Fallback, with layers that prefer collision, but are willing to fallback to walkable
    local collisionMapFallback = {}

	-- Map of structures that block placing other structures
	local blockPlacingStructuresMap = {}

	if (not self.map) then
		assert(false, 'No map loaded.')
		return collisionMap
	end

	local map = self.map

	for y = 1, map.height do
        collisionMap[y] = {}
		collisionMapFallback[y] = {}

		for x = 1, map.width do
            collisionMap[y][x] = WALKABLE
			collisionMapFallback[y][x] = WALKABLE
		end
	end

	for _, layer in ipairs(map.layers) do
		if (layer.data) then
			for y = 1, map.height do
				for x = 1, map.width do
					local tile = layer.data[y][x]

					if (tile) then
						-- Or if the entire layer is collidable, then any tile will be marked as collidable
						if (layer.properties.collidable) then
                            collisionMap[y][x] = NOT_WALKABLE

							if (not layer.properties.notStrictAboutCollidable) then
								collisionMapFallback[y][x] = NOT_WALKABLE
							end
						else
							if (layer.properties.reserved) then
                                -- For farmland, we want to mark it as walkable but reserved so no other farmland can be placed on it
                                if (not blockPlacingStructuresMap[y]) then
                                    blockPlacingStructuresMap[y] = {}
                                end

								blockPlacingStructuresMap[y][x] = true
							end
						end
					end
				end
			end
		end
	end

    self.collisionMap = collisionMap
    self.collisionGrid = Grid(collisionMap)

    self.collisionMapFallback = collisionMapFallback
	self.collisionGridFallback = Grid(collisionMapFallback)

    self.pathfinder = Pathfinder(self.collisionGrid, 'ASTAR', WALKABLE)
    self.pathfinder:setMode('ORTHOGONAL')

	self.pathfinderFallback = Pathfinder(self.collisionGridFallback, 'ASTAR', WALKABLE)
	self.pathfinderFallback:setMode('ORTHOGONAL')

	self.blockPlacingStructuresMap = blockPlacingStructuresMap

    if (GameConfig.debugCollisionMap) then
		print('\nCollision Map:\n')
		for y, row in ipairs(collisionMap) do
			local rowString = ''

			for x, value in ipairs(row) do
				rowString = rowString .. value
			end

			print(rowString)
		end
	end

	return collisionMap
end

--- Uses the pathfinder to find a path from the start to the end position.
--- @param startX number # The start X (0-based)
--- @param startY number # The start Y (0-based)
--- @param endX number # The end X (0-based)
--- @param endY number # The end Y (0-based)
--- @param withFallback? boolean # Whether to use the fallback pathfinder if the main one fails
--- @return table<number, table<number, number>> | nil # A table of path points (0-based) or nil if no path was found
function World:findPath(startX, startY, endX, endY, withFallback)
    if (not self.map) then
        assert(false, 'No map loaded.')
        return
    end

    -- The path finder works with 1-based indexes while the map is 0-based
    startX = startX + 1
    startY = startY + 1
    endX = endX + 1
    endY = endY + 1

	-- Ensure its within bounds of the map
	if (startX < 1 or startY < 1 or endX < 1 or endY < 1) then
		return nil
	end

	if (startX > self.map.width or startY > self.map.height or endX > self.map.width or endY > self.map.height) then
		return nil
	end

    -- Check if we have a cached path that is still valid
    local cachedPath = pathCache:find({
        startX = startX,
        startY = startY,
        endX = endX,
		endY = endY
    })

	local path

	if (cachedPath) then
		if (cachedPath.expiresAt < love.timer.getTime()) then
			cachedPath = nil
		else
			path = cachedPath.path
		end
	end

	if (not path) then
        path = self.pathfinder:getPath(startX, startY, endX, endY)

		if (not path and withFallback) then
			path = self.pathfinderFallback:getPath(startX, startY, endX, endY)
		end

		if (not path) then
			return nil
		end
	end

	if (not cachedPath) then
		-- Cache the path
		pathCache:push({
			startX = startX,
			startY = startY,
			endX = endX,
			endY = endY,
			path = path,
			expiresAt = love.timer.getTime() + PATH_EXPIRATION_TIME
		})
	end

    -- Convert back to 0-based indexes
    local points = {}

    for node, count in path:nodes() do
        table.insert(points, { x = node:getX() - 1, y = node:getY() - 1 })
    end

    return points
end

--- Checks if the tile at the given position is occupied.
--- @param x number
--- @param y number
--- @param isPlacingStructure? boolean
--- @param withFallback? boolean
--- @return boolean
function World:isTileOccupied(x, y, isPlacingStructure, withFallback)
	if (not self.map) then
		assert(false, 'No map loaded.')
		return false
	end

	local collisionMap = self.collisionMap

	if (not collisionMap) then
		return false
	end

    if (x < 0 or y < 0 or x >= #collisionMap[1] or y >= #collisionMap) then
        return true
    end

    x = x + 1
	y = y + 1

	if (isPlacingStructure) then
        if (self.blockPlacingStructuresMap[y] and self.blockPlacingStructuresMap[y][x]) then
			return true
		end
	end

	if (collisionMap[y][x] ~= NOT_WALKABLE) then
		return false
	end

	if (withFallback == true) then
		local collisionMapFallback = self.collisionMapFallback

		if (collisionMapFallback[y][x] ~= NOT_WALKABLE) then
			return false
		end
	end

	return true
end

--- Adds the given tile to the specified layer at the given position.
--- @param layerName string
--- @param tilesetIndex number
--- @param tileIndex number
--- @param x number
--- @param y number
function World:addTile(layerName, tilesetIndex, tileIndex, x, y)
    if (not self.map) then
        assert(false, 'No map loaded.')
        return
    end

    local layer = self.map.layers[layerName]

    if (not layer) then
        assert(false, 'Layer not found: ' .. layerName)
        return
    end

    -- Calculate the global tile ID (gid)
    local firstgid = self.map.tilesets[tilesetIndex].firstgid
    local gid = firstgid + tileIndex

    self.map:setLayerTile(layerName, x + 1, y + 1, gid)
end

--- Removes the tile at the given position from the specified layer.
--- @param layerName string
--- @param x number
--- @param y number
function World:removeTile(layerName, x, y)
	if (not self.map) then
		assert(false, 'No map loaded.')
		return
	end

	local layer = self.map.layers[layerName]

	if (not layer) then
		assert(false, 'Layer not found: ' .. layerName)
		return
	end

    x = x + 1
	y = y + 1

    self.map:setLayerTile(layerName, x, y, nil)
end

--- Adds a resource instance to the world
--- @param resource Resource
function World:addResourceInstance(resource)
	table.insert(self.resourceInstances, resource)
end

--- Find nearest resource instance to the given position
--- @param resourceType ResourceTypeRegistry.ResourceRegistration
--- @param x number
--- @param y number
--- @param filter? fun(resource: Resource): boolean
--- @return Resource|nil
function World:findNearestResourceInstance(resourceType, x, y, filter)
	local nearestResourceInstance = nil
	local nearestDistance = nil

	-- This currently finds all resources of the given type, but that will cause farmland of other factions to be used.
	for _, resource in ipairs(self.resourceInstances) do
		if (resource.resourceType == resourceType and (not filter or filter(resource))) then
			local distance = math.sqrt((resource.x - x) ^ 2 + (resource.y - y) ^ 2)

			if (not nearestDistance or distance < nearestDistance) then
				nearestResourceInstance = resource
				nearestDistance = distance
			end
		end
	end

	return nearestResourceInstance
end

--- Find the nearest interactable to the given position
--- @param x number
--- @param y number
--- @param filter function|nil
--- @return Interactable|nil
function World:findNearestInteractable(x, y, filter)
	local nearestInteractable = nil
	local nearestDistance = nil

	for _, faction in ipairs(self.factions) do
		for _, unit in ipairs(faction:getUnits()) do
			if (not filter or filter(unit)) then
				local distance = math.sqrt((unit.x - x) ^ 2 + (unit.y - y) ^ 2)

				if (not nearestDistance or distance < nearestDistance) then
					nearestInteractable = unit
					nearestDistance = distance
				end
			end
		end

		for _, structure in ipairs(faction:getStructures()) do
			if (not filter or filter(structure)) then
				local distance = math.sqrt((structure.x - x) ^ 2 + (structure.y - y) ^ 2)

				if (not nearestDistance or distance < nearestDistance) then
					nearestInteractable = structure
					nearestDistance = distance
				end
			end
		end
	end

	return nearestInteractable
end

--- Removes the given resource instance from the world
--- @param resource Resource
function World:removeResourceInstance(resource)
	for i, instance in ipairs(self.resourceInstances) do
        if (instance == resource) then
			table.remove(self.resourceInstances, i)
			return
		end
	end
end

--- Get all resource instances
--- @return Resource[]
function World:getResourceInstances()
	return self.resourceInstances
end

--- Get all resource instances of the given type
--- @param resourceType ResourceTypeRegistry.ResourceRegistration
--- @return Resource[]
function World:getResourceInstancesOfType(resourceType)
	local instances = {}

	for _, resource in ipairs(self.resourceInstances) do
		if (resource.resourceType == resourceType) then
			table.insert(instances, resource)
		end
	end

	return instances
end

--- Gets the unit or structure under the given world position
--- @param x number
--- @param y number
--- @return Unit|Structure|Resource|nil
function World:getInteractableUnderPosition(x, y)
	for _, resource in ipairs(self.resourceInstances) do
        if (resource:isInPosition(x, y)) then
			return resource
		end
	end

	for _, faction in ipairs(self.factions) do
		for _, unit in ipairs(faction:getUnits()) do
			if (unit:isInPosition(x, y)) then
				return unit
			end
		end
	end

    for _, faction in ipairs(self.factions) do
		for _, structure in ipairs(faction:getStructures()) do
			if (structure:isInPosition(x, y)) then
				return structure
			end
		end
	end

	return nil
end

--- Adds a faction to the world
--- @param faction Faction
function World:addFaction(faction)
	faction:setWorld(self)
	table.insert(self.factions, faction)
end

--- Checks if the faction is already in the world
--- @param faction Faction
--- @return boolean
function World:hasFaction(faction)
	for _, f in ipairs(self.factions) do
		if (f == faction) then
			return true
		end
	end

	return false
end

--- Spawns a faction in a spawnpoint of the world, creating a town hall and a worker
--- @param faction Faction
function World:spawnFaction(faction)
	if (not self.map) then
		assert(false, 'No map loaded.')
		return
	end

	local spawnpoint = self.spawnPoints[#self.factions + 1]

	assert(spawnpoint, 'No spawnpoint found for faction.')

	assert(not self:hasFaction(faction), 'Faction already in the world.')
	self:addFaction(faction)

    local townHallStructureType = StructureTypeRegistry:getStructureType('town_hall')
    local townHall = faction:spawnStructure(townHallStructureType, spawnpoint.x, spawnpoint.y, nil, FORCE_FREE_PLACEMENT)

	townHall.events:on('structureRemoved', function()
        print('Town hall removed, faction lost.')
		faction:remove()
	end)
end

--- Removes the faction from the world
--- @param faction Faction
function World:removeFaction(faction)
    for i, f in ipairs(self.factions) do
        if (f == faction) then
            table.remove(self.factions, i)
            return
        end
    end
end

--- Adds a faction to the fog of war factions, so we can see what they see through the fog of war
--- @param faction Faction
function World:addFogOfWarFaction(faction)
    if (self.fogOfWarFactions[faction]) then
        return
    end

	self.fogOfWarFactions[faction] = true
	self:resetFogOfWar()
end

--- Removes a faction from the fog of war factions
--- @param faction Faction
function World:removeFogOfWarFaction(faction)
	if (not self.fogOfWarFactions[faction]) then
		return
	end

	self.fogOfWarFactions[faction] = nil
	self:resetFogOfWar()
end

--- Clears all fog of war factions
--- @param faction Faction
function World:clearFogOfWarFactions()
    self.fogOfWarFactions = {}
    self:resetFogOfWar()
end

--- Creates a fog of war map for the faction, so we can track discovered tiles
--- @param faction Faction
--- @return table<number, table<number, boolean>>
function World:createFogOfWarMap(faction)
	local map = {}

	for y = 1, self.map.height do
		map[y] = {}

		for x = 1, self.map.width do
			map[y][x] = false
		end
	end

	return map
end

--- Reveals a section of the fog of war for the faction
--- @param faction Faction
--- @param fogOfWarMap table<number, table<number, boolean>>
--- @param x number
--- @param y number
--- @param radius number
function World:revealFogOfWar(faction, fogOfWarMap, x, y, radius)
    local map = self.map

	-- Circle, but looks a bit weird with single tiles at some edges:
	-- local changedTiles = {}

	-- for dy = -radius, radius do
	-- 	for dx = -radius, radius do
	-- 		if (dx * dx + dy * dy <= radius * radius) then
	-- 			local nx = math.ceil(x + dx) + 1
	-- 			local ny = math.ceil(y + dy) + 1

	-- 			if (nx >= 1 and ny >= 1 and nx <= map.width and ny <= map.height) then
	-- 				fogOfWarMap[ny][nx] = true
	-- 				table.insert(changedTiles, { x = nx - 1, y = ny - 1 })
	-- 			end
	-- 		end
	-- 	end
    -- end

	-- More smoothened circle:
    local changedTiles = {}

    for dy = -radius, radius do
        for dx = -radius, radius do
            local distanceSquared = dx * dx + dy * dy

            -- Reveal inner circle (full radius)
            if distanceSquared <= radius * radius then
                local nx = math.ceil(x + dx) + 1
                local ny = math.ceil(y + dy) + 1

                if (nx >= 1 and ny >= 1 and nx <= map.width and ny <= map.height) then
                    fogOfWarMap[ny][nx] = true
                    table.insert(changedTiles, { x = nx - 1, y = ny - 1 })
                end

            -- Reveal outer edge to ensure a 2-pixel border (outer radius)
            elseif distanceSquared <= (radius + 0.5) * (radius + 0.5) then
                local nx = math.ceil(x + dx) + 1
                local ny = math.ceil(y + dy) + 1

                if (nx >= 1 and ny >= 1 and nx <= map.width and ny <= map.height) then
                    fogOfWarMap[ny][nx] = true
                    table.insert(changedTiles, { x = nx - 1, y = ny - 1 })
                end
            end
        end
    end

	self:updateFogOfWarForFaction(faction, changedTiles)
end

--- Updates the fog of war
function World:resetFogOfWar()
    if (not self.map) then
        assert(false, 'No map loaded.')
        return
    end

    local map = self.map

    local fogOfWarLayer = map.layers[GameConfig.fogOfWarLayerName]

    if (not fogOfWarLayer) then
        return
    end

    local fogOfWarTileset = map.tilesets[GameConfig.fogOfWarTilesetId]

    if (not fogOfWarTileset) then
        return
    end

	if (GameConfig.disableFogOfWar) then
		-- Clear the fog of war
        for y = 1, map.height do
            for x = 1, map.width do
                map:setLayerTile(GameConfig.fogOfWarLayerName, x, y, nil)
            end
        end

		return
	end

    local fogOfWarTileId = fogOfWarTileset.firstgid + GameConfig.fogOfWarTileId

    -- Set the fog of war for all tiles
    for y = 1, map.height do
        for x = 1, map.width do
            map:setLayerTile(GameConfig.fogOfWarLayerName, x, y, fogOfWarTileId)
        end
    end

    -- Reveal the fog of war for whatever is currently visible
	for faction, _ in pairs(self.fogOfWarFactions) do
		self:updateFogOfWarForFaction(faction)
	end
end

--- Checks if the given faction is in the fog of war factions, then updates the fog of war
--- for it.
--- @param faction Faction
--- @param changedTiles? table<number, table<number, number>>
function World:updateFogOfWarForFaction(faction, changedTiles)
    if (GameConfig.disableFogOfWar) then
        return
    end

	if (not self.fogOfWarFactions[faction]) then
		return
	end

	local map = self.map

	local fogOfWarLayer = map.layers[GameConfig.fogOfWarLayerName]
    assert(fogOfWarLayer, 'Fog of war layer not found.')

    local fogOfWarTileset = map.tilesets[GameConfig.fogOfWarTilesetId]
	assert(fogOfWarTileset, 'Fog of war tileset not found.')

	local fogOfWarTileId = fogOfWarTileset.firstgid + GameConfig.fogOfWarTileId

    local fogOfWarMap = faction.fogOfWarMap
	assert(fogOfWarMap, 'Fog of war map not found for faction.')

	-- Only update the changed tiles if we have them
	if (changedTiles) then
        for _, tile in ipairs(changedTiles) do
			local x = tile.x + 1
			local y = tile.y + 1

			if (x >= 1 and y >= 1 and x <= map.width and y <= map.height) then
				if (fogOfWarMap[y][x]) then
					map:setLayerTile(GameConfig.fogOfWarLayerName, x, y, nil)
				else
					map:setLayerTile(GameConfig.fogOfWarLayerName, x, y, fogOfWarTileId)
				end
			end
		end
	else
		for y = 1, map.height do
			for x = 1, map.width do
				if (fogOfWarMap[y][x]) then
					map:setLayerTile(GameConfig.fogOfWarLayerName, x, y, nil)
				else
					map:setLayerTile(GameConfig.fogOfWarLayerName, x, y, fogOfWarTileId)
				end
			end
		end
	end
end

--- Called to check if the interactable should be drawn for the player, respecting the fog of war
--- @param player Player
--- @param interactable Interactable
--- @return boolean
function World:isInteractableDiscoveredForPlayer(player, interactable)
	if (GameConfig.disableFogOfWar) then
		return true
	end

	local faction = player:getFaction()
	local fogOfWarMap = faction.fogOfWarMap
	assert(fogOfWarMap, 'Fog of war map not found for faction.')

	local x, y = interactable:getWorldPosition()

	return fogOfWarMap[y + 1][x + 1]
end

return World
