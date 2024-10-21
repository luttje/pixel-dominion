-- Original Source: https://github.com/karai17/Simple-Tiled-Implementation
-- Modified for our use case.
local Sti = require('third-party.sti')
local Grid = require('third-party.jumper.grid')
local Pathfinder = require('third-party.jumper.pathfinder')

WALKABLE, NOT_WALKABLE = 0, 1

--- Represents a world that contains factions
--- @class World
--- @field mapPath string # The path to the map file
--- @field factions Faction[] # The factions in the world
--- @field resourceInstances ResourceInstance[] # The resource instances in the world
local World = DeclareClass('World')

--- Initializes the world
--- @param config table
function World:initialize(config)
	config = config or {}

	assert(config.mapPath, 'Map path is required.')

    self.factions = {}
	self.resourceInstances = {}

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

	-- Cache the static collision map
	local collisionMap = self:updateCollisionMap()

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
	local collisionMap = {}

	if (not self.map) then
		assert(false, 'No map loaded.')
		return collisionMap
	end

	local map = self.map

	for y = 1, map.height do
		collisionMap[y] = {}

		for x = 1, map.width do
			collisionMap[y][x] = WALKABLE
		end
	end

	for _, layer in ipairs(map.layers) do
		if (layer.data) then
			for y = 1, map.height do
				for x = 1, map.width do
					local tile = layer.data[y][x]

					if (tile) then
						-- If the tile has a property 'collidable' set to true, then mark it as collidable
						-- Or if the entire layer is collidable, then any tile will be marked as collidable
						if (tile.properties.collidable or layer.properties.collidable) then
							collisionMap[y][x] = NOT_WALKABLE
						else
							collisionMap[y][x] = WALKABLE
						end
					end
				end
			end
		end
	end

    self.collisionMap = collisionMap
	self.collisionGrid = Grid(collisionMap)
    self.pathfinder = Pathfinder(self.collisionGrid, 'ASTAR', WALKABLE)
	self.pathfinder:setMode('ORTHOGONAL')

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
--- @return table<number, table<number, number>> | nil # A table of path points (0-based) or nil if no path was found
function World:findPath(startX, startY, endX, endY)
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

    local path = self.pathfinder:getPath(startX, startY, endX, endY)

    if (not path) then
        return nil
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
--- @return boolean
function World:isTileOccupied(x, y)
	if (not self.map) then
		assert(false, 'No map loaded.')
		return
	end

	local collisionMap = self.collisionMap

	if (not collisionMap) then
		return false
	end

	if (x < 0 or y < 0 or x >= #collisionMap[1] or y >= #collisionMap) then
		return true
	end

	return collisionMap[y + 1][x + 1] == NOT_WALKABLE
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
--- @param resourceInstance ResourceInstance
function World:addResourceInstance(resourceInstance)
	table.insert(self.resourceInstances, resourceInstance)
end

--- Removes the given resource instance from the world
--- @param resourceInstance ResourceInstance
function World:removeResourceInstance(resourceInstance)
	for i, instance in ipairs(self.resourceInstances) do
        if (instance == resourceInstance) then
			table.remove(self.resourceInstances, i)
			return
		end
	end
end

--- Gets the unit or structure under the given world position
--- @param x number
--- @param y number
--- @return Unit|Structure|ResourceInstance|nil
function World:getInteractableUnderPosition(x, y)
	for _, faction in ipairs(self.factions) do
		for _, unit in ipairs(faction:getUnits()) do
			if (unit:isInPosition(x, y)) then
				return unit
			end
		end
	end

	-- TODO:
    -- for _, faction in ipairs(self.factions) do
	-- 	for _, structure in ipairs(faction:getStructures()) do
	-- 		if (structure:isInPosition(x, y)) then
	-- 			return structure
	-- 		end
	-- 	end
	-- end

	for _, resourceInstance in ipairs(self.resourceInstances) do
        if (resourceInstance:isInPosition(x, y)) then
			return resourceInstance
		end
	end

	return nil
end

--- Adds a faction to the world
--- @param faction Faction
function World:addFaction(faction)
	table.insert(self.factions, faction)
end

return World
