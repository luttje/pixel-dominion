local RegionManager = DeclareClass('RegionManager')

RegionManager.registeredRegions = {}
RegionManager.currentRegion = nil

function RegionManager:registerRegion(region)
	table.insert(self.registeredRegions, region)
	region.index = #self.registeredRegions

	return region
end

function RegionManager:getCurrentRegion()
    return self.currentRegion
end

--- Has the player enter the region and gives
--- @param region Region|number The region or the index of the region.
--- @param player Player The player to be entered into the region
function RegionManager:setCurrentRegion(region, player)
	if (type(region) == 'number') then
		self.currentRegion = self.registeredRegions[region]
	else
		self.currentRegion = region
	end

	if (not self.currentRegion) then
		-- Instead of failing, we will just generate a new region.
		-- assert(self.currentRegion, 'Region not found: ' .. tostring(region))
		self.currentRegion = self:generateProceduralRegion()
	end
end

function RegionManager:generateProceduralRegion()
	return self:registerRegion(Region({
		name = 'Procedural Region',
	}))
end

--- Loads the world data from all the regions the player has unlocked or
--- is about to unlock.
--- Combines the world data layers and only uses the last unlocked homePosition
--- @param player Player
--- @return table, table # The world data and a table of the x, y, width and height of the region to draw
function RegionManager:getWorldDataForPlayer(player)
	local combinedWorldData = {
		layers = {},
    }

	local minX, minY, maxX, maxY

    for regionIndex = 1, player:getRegionIndex() do
		local region = self.registeredRegions[regionIndex]
		local regionWorldData = region.worldData

		assert(regionWorldData.layers, 'Region world data must have layers, region: ' .. region.name)

		for _, layer in ipairs(regionWorldData.layers) do
			table.insert(combinedWorldData.layers, layer)
		end

		if (regionWorldData.homePosition) then
			combinedWorldData.homePosition = regionWorldData.homePosition
		end

        assert(regionWorldData.x, 'Region world data must have an x, region: ' .. region.name)
        assert(regionWorldData.y, 'Region world data must have a y, region: ' .. region.name)
        assert(regionWorldData.width, 'Region world data must have a width, region: ' .. region.name)
        assert(regionWorldData.height, 'Region world data must have a height, region: ' .. region.name)

        if (not minX or regionWorldData.x < minX) then
            minX = regionWorldData.x
        end

        if (not minY or regionWorldData.y < minY) then
            minY = regionWorldData.y
        end

        if (not maxX or regionWorldData.x + regionWorldData.width > maxX) then
            maxX = regionWorldData.x + regionWorldData.width
        end

		if (not maxY or regionWorldData.y + regionWorldData.height > maxY) then
			maxY = regionWorldData.y + regionWorldData.height
		end
	end

	return self:initializeWorldData(combinedWorldData), {
		x = minX,
        y = minY,
        endX = maxX,
		endY = maxY,
		width = maxX - minX,
		height = maxY - minY,
	}
end

--- Goes through the world data and turns the image paths into actual images
--- and colors into actual color objects
function RegionManager:initializeWorldData(worldData)
	for _, layer in ipairs(worldData.layers) do
        for _, tile in ipairs(layer.tiles) do
            assert(tile.imagePath, 'Tile must have an image path')

            tile.image = ImageCache:get(tile.imagePath)

            if (tile.color) then
                tile.color = Colors.fromRgb(tile.color[1], tile.color[2], tile.color[3])
            end
        end
    end

    return worldData
end

function RegionManager:getWorldDataUnlockedRegions(worldData, player)
	local unlockedAreas = {}

	-- TODO: For now we ensure the hut is always unlocked, but we should make this more dynamic.
	local unlockedIndex = math.max(1, player:getRegionIndex() - 1)

	for regionIndex = 1, unlockedIndex do
		local region = self.registeredRegions[regionIndex]
		local regionWorldData = region.worldData

		-- For each region we just want the area of the region, not the whole world data.
		table.insert(unlockedAreas, {
			x = regionWorldData.x,
			y = regionWorldData.y,
			endX = regionWorldData.x + regionWorldData.width - 1,
			endY = regionWorldData.y + regionWorldData.height - 1,
			width = regionWorldData.width,
			height = regionWorldData.height,
		})
	end

	return unlockedAreas
end

function RegionManager:getWorldDataForRegionIndex(regionIndex)
	local region = self.registeredRegions[regionIndex]
	local regionWorldData = region.worldData

	return {
		index = regionIndex,
		x = regionWorldData.x,
		y = regionWorldData.y,
		endX = regionWorldData.x + regionWorldData.width - 1,
		endY = regionWorldData.y + regionWorldData.height - 1,
		width = regionWorldData.width,
		height = regionWorldData.height,
		isActive = regionIndex == self.currentRegion.index,
	}
end

--- Returns the single region that is about to be unlocked.
function RegionManager:getWorldDataUnlockingRegion(player)
	local unlockingIndex = player:getRegionIndex()

	assert(unlockingIndex < #self.registeredRegions, 'Player is trying to unlock a region that does not exist')

	return self:getWorldDataForRegionIndex(unlockingIndex)
end

return RegionManager
