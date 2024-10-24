--- @class ResourceTypeRegistry
local ResourceTypeRegistry = DeclareClass('ResourceTypeRegistry')

--[[
	ResourceRegistration
--]]

--- @class ResourceTypeRegistry.ResourceRegistration
---
--- @field id string The unique id of the resource type.
--- @field name string The name of the resource type.
--- @field image Image The image representing the resource type.
--- @field defaultValue number The default value of the resource type.
--- @field formatValue fun(resourceType: ResourceTypeRegistry.ResourceRegistration, value: number): string A function that formats the value of the resource type.
---
--- @field harvestableTilesetInfo table<number, table> The tileset information used to render the resource in the world.
--- @field spawnAtTileId string The id of the tileset to spawn the resource at.
ResourceTypeRegistry.ResourceRegistration = DeclareClass('ResourceTypeRegistry.ResourceRegistration')

function ResourceTypeRegistry.ResourceRegistration:initialize(config)
	assert(config.id, 'Resource id is required.')
	assert(config.imagePath, 'Resource imagePath is required.')

    self.image = ImageCache:get(config.imagePath)

	config = config or {}

	table.Merge(self, config)
end

--- Creates a new resource value instance
--- @return ResourceValue
function ResourceTypeRegistry.ResourceRegistration:newValue()
	return ResourceValue({
		resourceType = self,
		value = 0
	})
end

--- Checks if the resource is harvestable
--- @return boolean
function ResourceTypeRegistry.ResourceRegistration:isHarvestable()
	return self.harvestableTilesetInfo ~= nil or self.forceHarvestable
end

--- Draws the resource type icon
--- @param x number
--- @param y number
--- @param width number
--- @param height number
function ResourceTypeRegistry.ResourceRegistration:draw(x, y, width, height)
    love.graphics.draw(self.image, x, y, 0, width / self.image:getWidth(), height / self.image:getHeight())
end

--- Spawns this resource at the given tile position
--- @param world World The world to spawn the resource in
--- @param x number
--- @param y number
--- @return Resource
function ResourceTypeRegistry.ResourceRegistration:spawnAtTile(world, x, y)
    assert(self.spawnAtTileId, 'Resource spawnAtTileId is required.')
    assert(self.harvestableTilesetInfo, 'Resource harvestableTilesetInfo is required.')

	local tiles = {}
	local treeInfo = table.Random(self.harvestableTilesetInfo)

	for _, tileInfo in ipairs(treeInfo.tiles) do
		local worldX = x + (tileInfo.offsetX or 0)
		local worldY = y + (tileInfo.offsetY or 0)

		world:addTile(
			tileInfo.targetLayer,
			tileInfo.tilesetId,
			tileInfo.tileId,
			worldX,
			worldY
		)

		-- Track the tiles that belong to this resource so they can be removed later
		tiles[#tiles + 1] = {
			layerName = tileInfo.targetLayer,
			tilesetId = tileInfo.tilesetId,
			tileId = tileInfo.tileId,
			x = worldX,
			y = worldY,
            offsetX = tileInfo.offsetX or 0,
			offsetY = tileInfo.offsetY or 0
		}
	end

	world:updateCollisionMap()

	local resource = Resource({
		resourceType = self,
		x = x,
        y = y,
        tiles = tiles,
		interactSounds = treeInfo.harvestSounds
    })

    resource:onSpawn()

	return resource
end

--[[
	Registry methods
--]]

local registeredResourceTypes = {}
local registeredResourceTypeMap = {}

function ResourceTypeRegistry:registerResourceType(resourceId, config)
    config = config or {}
    config.id = resourceId

    local index = #registeredResourceTypes + 1
    registeredResourceTypes[index] = ResourceTypeRegistry.ResourceRegistration(config)

    self:sortByWeight()
    self:updateMap()

    return registeredResourceTypes[resourceId]
end

function ResourceTypeRegistry:sortByWeight()
	table.sort(registeredResourceTypes, function(a, b)
		return a.orderWeight < b.orderWeight
	end)
end

function ResourceTypeRegistry:updateMap()
	for index, resourceType in ipairs(registeredResourceTypes) do
		registeredResourceTypeMap[resourceType.id] = index
	end
end

function ResourceTypeRegistry:removeResourceType(resourceId)
	local index = registeredResourceTypeMap[resourceId]

	if (index) then
		registeredResourceTypes[index] = nil
		registeredResourceTypeMap[resourceId] = nil
	end
end

function ResourceTypeRegistry:getResourceType(resourceId)
	local index = registeredResourceTypeMap[resourceId]

	if (index) then
		return registeredResourceTypes[index]
	end

	return nil
end

--- Gets a random resource type, optionally filtered by a function
--- @param filter? fun(resourceType: ResourceTypeRegistry.ResourceRegistration): boolean
--- @return ResourceTypeRegistry.ResourceRegistration
function ResourceTypeRegistry:getRandomResourceType(filter)
    if (not filter) then
        return table.Random(registeredResourceTypes)
    end

    local filteredResourceTypes = {}

	for _, resourceType in ipairs(registeredResourceTypes) do
		if (filter(resourceType)) then
			filteredResourceTypes[#filteredResourceTypes + 1] = resourceType
		end
	end

	return table.Random(filteredResourceTypes)
end

function ResourceTypeRegistry:getAllResourceTypes()
	return registeredResourceTypes
end

return ResourceTypeRegistry
