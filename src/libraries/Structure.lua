require('libraries.Interactable')

--- Represents a structure value in the game
--- @class Structure : Interactable
--- @field structureType StructureTypeRegistry.StructureRegistration
--- @field faction Faction
--- @field supply number
--- @field tiles table
local Structure = DeclareClassWithBase('Structure', Interactable)

--- Initializes the structure
--- @param config table
function Structure:initialize(config)
    config = config or {}

    -- Easier on mobile if not selectable
    self.isSelectable = false

    table.Merge(self, config)
end

--- Called when the structure spawns
--- @param builders Unit[]
function Structure:onSpawn(builders)
	if (self.structureType.onSpawn) then
		self.structureType:onSpawn(self, builders)
	end
end

--- Gets the type of structure
--- @return StructureTypeRegistry.StructureRegistration
function Structure:getStructureType()
	return self.structureType
end

--- Gets the faction
--- @return Faction
function Structure:getFaction()
	return self.faction
end

--- Checks if the interactable is in the given position
--- @param x number
--- @param y number
--- @return boolean
function Structure:isInPosition(x, y)
	-- We check all tiles
	for _, tile in ipairs(self.tiles) do
		if (tile.x == x and tile.y == y) then
			return true
		end
	end

	return false
end

--- Draws the interactable on the hud
--- @param x number
--- @param y number
--- @param width number
--- @param height number
function Structure:drawHudIcon(x, y, width, height)
	self.structureType:drawHudIcon(self, x, y, width, height)
end

--- Called after the structure is drawn on screen
--- @param x number
--- @param y number
--- @param width number
--- @param height number
--- @param cameraScale number
function Structure:postDrawOnScreen(x, y, width, height, cameraScale)
	if (self.structureType.postDrawOnScreen) then
		local minX, minY, maxX, maxY = self:getScreenBounds(x, y, cameraScale)

		-- if (self:getIsSelected()) then
		-- 	self:drawScreenBorder(minX, minY, maxX, maxY)
		-- end

		self.structureType:postDrawOnScreen(self, minX, minY, maxX, maxY)
	end
end

--- Returns the draw offset of the structure. We use the bounds to ensure the selection marker is drawn above the center
--- of all tiles instead of the bottom left corner of the structure
--- @return number, number
function Structure:getDrawOffset()
	-- Go through all tiles and return half the width and height as the offset
	local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge

	for _, tile in ipairs(self.tiles) do
		minX = math.min(minX, tile.x)
		minY = math.min(minY, tile.y)
		maxX = math.max(maxX, tile.x)
		maxY = math.max(maxY, tile.y)
	end

	-- TODO: This probably won't work for all structures, especially those that don't have the bottom left corner as the origin
	return (maxX - minX) * .5 * GameConfig.tileSize, (maxY - minY) * -1 * GameConfig.tileSize
end

--- Gets the bounds of the structure on screen
--- @param screenX number
--- @param screenY number
--- @param cameraScale number
--- @return number, number, number, number
function Structure:getScreenBounds(screenX, screenY, cameraScale)
	local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge

	for _, tile in ipairs(self.tiles) do
		local tileX = screenX + tile.offsetX * GameConfig.tileSize * cameraScale
		local tileY = screenY + tile.offsetY * GameConfig.tileSize * cameraScale

		minX = math.min(minX, tileX)
		minY = math.min(minY, tileY)
		maxX = math.max(maxX, tileX + GameConfig.tileSize * cameraScale)
		maxY = math.max(maxY, tileY + GameConfig.tileSize * cameraScale)
	end

	return minX, minY, maxX, maxY
end

--- Draws the border of the structure on screen
--- @param minX number
--- @param minY number
--- @param maxX number
--- @param maxY number
function Structure:drawScreenBorder(minX, minY, maxX, maxY)
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle('line', minX, minY, maxX - minX, maxY - minY)
end

--- Called every tick
--- @param deltaTime number
function Structure:update(deltaTime)
	if (not self.nextUpdateTime) then
		self.nextUpdateTime = GameConfig.structureUpdateTimeInSeconds
	end

	self.nextUpdateTime = self.nextUpdateTime - deltaTime

	if (self.nextUpdateTime <= 0) then
		self.nextUpdateTime = GameConfig.structureUpdateTimeInSeconds

		if (self.structureType.onTimedUpdate) then
			self.structureType:onTimedUpdate(self)
		end
	end
end

--- When an interactable is interacted with
--- @param deltaTime number
--- @param interactor Interactable
function Structure:updateInteract(deltaTime, interactor)
	if (not interactor:isOfType(Unit)) then
		print('Cannot interact with structure as it is not a unit.')
		return
	end

	if (self.structureType.updateInteract) then
		self.structureType:updateInteract(self, deltaTime, interactor)
	end
end

--- Removes the structure from the world
function Structure:removeStructure()
    if (self.isRemoved) then
        return
    end

    self.isRemoved = true

    local world = CurrentWorld

    for _, tile in pairs(self.tiles) do
        world:removeTile(tile.layerName, tile.x, tile.y)
    end

    world:updateCollisionMap()

	if (self.structureType.onRemove) then
		self.structureType:onRemove(self)
	end

    self.events:trigger('structureRemoved')
end

return Structure
