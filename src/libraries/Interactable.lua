--- Represents an interactable object in the world
--- @class Interactable
---
--- @field id number # The id of the interactable
---
--- @field world World # The world the interactable is in
--- @field x number # The x position of the interactable
--- @field y number # The y position of the interactable
--- @field faction? Faction
---
--- @field isSelected boolean # Whether the interactable is selected
--- @field isSelectable boolean # Whether the interactable is selectable
--- @field isRemoved boolean # Whether the interactable is removed
---
--- @field interactSounds table|nil
--- @field sightRange number
---
--- @field tiles? table
--- @field tilesDiscovered boolean
---
--- @field health number
--- @field maxHealth number
--- @field nextDamagableAt number
--- @field lastDamagedBy Interactable
--- @field lastDamagedInteractable Interactable
---
local Interactable = DeclareClass('Interactable')

local NEXT_ID = 1

--- Initializes the interactable
--- @param config table
function Interactable:initialize(config)
	assert(config.world, 'Interactable must have a world set.')

	self.isSelectable = true
	self.health = 100
	self.sightRange = 6

	self.tiles = nil
    self.tilesDiscovered = false

    table.Merge(self, config)

	self.maxHealth = self.health

	self.events = EventManager({
		target = self
	})

    self.id = NEXT_ID
	NEXT_ID = NEXT_ID + 1

    self.world.searchTree:insert(self)

	if (self.faction) then
		self.faction:onInteractableMoved(self)
	end

	if (self.tiles) then
		-- Place invisible tiles for the interactable, so we correctly update the collision map
		-- Without this the AI players would walk through the interactable + spawn structures on top of it
		for _, tile in ipairs(self.tiles) do
			self.world:addTile(
				tile.layerName,
				GameConfig.invisibleTilesetId,
				GameConfig.invisibleTileId,
				tile.x,
				tile.y
			)
		end

		self.world:updateCollisionMap()
	end
end

--- Sets the world for the interactable
--- @param world World
function Interactable:setWorld(world)
    self.world = world
end

--- Gets the world for the interactable
--- @return World
function Interactable:getWorld()
	return self.world
end

--- Sets the faction
--- @param faction Faction
function Interactable:setFaction(faction)
	self.faction = faction
end

--- Gets the faction
--- @return Faction
function Interactable:getFaction()
    return self.faction
end

--- When an interactable is interacted with
--- @param interactable Interactable
function Interactable:interact(interactable)
	-- Override this in the child class
end

--- Applies damage to the interactable
--- @param damage number
--- @param interactor Interactable # The interactable that caused the damage
--- @return boolean # Whether the interactable was destroyed
function Interactable:damage(damage, interactor)
    if (self.health <= 0) then
        return true
    end

    self.health = self.health - damage

    if (self.health <= 0) then
        self:remove()
        return true
    end

    return false
end

--- Removes the interactable from the world
function Interactable:remove()
    -- Override this in the child class and call this with
    -- self:getBase():remove()

    self.isRemoved = true

	local world = self:getWorld()

	if (self.tiles) then
        for _, tile in pairs(self.tiles) do
            world:removeTile(tile.layerName, tile.x, tile.y)
        end

		world:updateCollisionMap()
	end
end

--- Draws the interactable on the hud
--- @param x number
--- @param y number
--- @param width number
--- @param height number
function Interactable:drawHudIcon(x, y, width, height)
	-- Override this in the child class
end

--- Called after the interactable is drawn on screen
--- @param x number
--- @param y number
--- @param width number
--- @param height number
--- @param cameraScale number
function Interactable:postDrawOnScreen(x, y, width, height, cameraScale)
	-- Override this in the child class and call the base class like:
    -- self:getBase():postDrawOnScreen(x, y, width, height, cameraScale)

    local world = self:getWorld()

    if (not world:isInteractableDiscoveredForFaction(CurrentPlayer:getFaction(), self)) then
        return
    end

	-- If the tiles have not been discovered through the fog of war, draw them and update the collision map
	if (self.tiles and not self.tilesDiscovered) then
		self.tilesDiscovered = true

		for _, tile in ipairs(self.tiles) do
			-- Oddly the swapTile function inside setLayerTile doesn't work, so we remove and add the tile
			world:removeTile(tile.layerName, tile.x, tile.y)
			world:addTile(
				tile.layerName,
				tile.tilesetId,
				tile.tileId,
				tile.x,
				tile.y
			)
		end
	end

    -- Draw the health bar above the interactable
	if (self.health < self.maxHealth) then
		local healthBarWidth = width
		local healthBarHeight = 5
		local healthBarX = x
        local healthBarY = y - healthBarHeight - Sizes.padding()

		love.graphics.setColor(1, 0, 0)
		love.graphics.rectangle('fill', healthBarX, healthBarY, healthBarWidth, healthBarHeight)

		love.graphics.setColor(0, 1, 0)
		love.graphics.rectangle('fill', healthBarX, healthBarY, healthBarWidth * (self.health / self.maxHealth), healthBarHeight)

        love.graphics.setColor(0, 0, 0)
		love.graphics.rectangle('line', healthBarX, healthBarY, healthBarWidth, healthBarHeight)
	end
end

--- Gets the world position of the interactable
--- @return number, number
function Interactable:getWorldPosition()
    return self.x, self.y
end

--- Sets the position of the interactable
--- @param x number
--- @param y number
function Interactable:setWorldPosition(x, y)
    self.world.searchTree:remove(self)

	self.x = x
    self.y = y

    self.world.searchTree:insert(self)

    -- If we have a faction, inform it of the change so it can update the fog of war
	if (self.faction) then
		self.faction:onInteractableMoved(self)
	end
end

--- Checks if the interactable is in the given position
--- @param x number
--- @param y number
--- @return boolean
function Interactable:isInPosition(x, y)
	-- We check all tiles if we have a multi-tile interactable
	if (self.tiles) then
		for _, tile in ipairs(self.tiles) do
			if (tile.x == x and tile.y == y) then
				return true
			end
		end
	end

	return self.x == x and self.y == y
end

--- Gets if the interactable is in the camera view, returns the on screen position and size if it is
--- @param scaledCameraOffsetX number
--- @param scaledCameraOffsetY number
--- @param cameraWidth number
--- @param cameraHeight number
--- @param cameraWorldScale number
--- @return table|boolean
function Interactable:isInCameraView(scaledCameraOffsetX, scaledCameraOffsetY, cameraWidth, cameraHeight, cameraWorldScale)
    local onScreenX = (self.x * GameConfig.tileSize * cameraWorldScale) - scaledCameraOffsetX
    local onScreenY = (self.y * GameConfig.tileSize * cameraWorldScale) - scaledCameraOffsetY

    local onScreenWidth = GameConfig.tileSize * cameraWorldScale
    local onScreenHeight = GameConfig.tileSize * cameraWorldScale

    if (onScreenX >= 0 and onScreenX <= cameraWidth and onScreenY >= 0 and onScreenY <= cameraHeight) then
        return {
            x = onScreenX,
            y = onScreenY,
            width = onScreenWidth,
            height = onScreenHeight
        }
    end

	return false
end

--- Get the distance to the given position. Returned as a squared value for performance reasons.
--- @param x number
--- @param y number
--- @return number
function Interactable:getDistanceTo(x, y)
	return math.pow(self.x - x, 2) + math.pow(self.y - y, 2)
end

--- Selects the interactable
--- @param selected boolean
function Interactable:setSelected(selected)
    if (not self.isSelectable) then
        return
    end

    assert(CurrentPlayer, 'Selecting only supported for the current player.')

    self.isSelected = selected

	if (selected) then
		CurrentPlayer:addSelectedInteractable(self)
	else
		CurrentPlayer:removeSelectedInteractable(self)
	end
end

--- Gets if the interactable is selected
--- @return boolean
function Interactable:getIsSelected()
	return self.isSelected
end

--- Finds a free tile nearby the Interactable
--- @param interactables? Interactable[]
--- @param nearX? number
--- @param nearY? number
--- @param searchRange? number
--- @return number?, number?
function Interactable:getFreeTileNearby(interactables, nearX, nearY, searchRange)
    nearX, nearY = nearX or self.x, nearY or self.y
	searchRange = searchRange or 1

    -- Look further and further away until we find a free tile is found.
	for range = 1, searchRange do
		for _, offset in pairs(GameConfig.tileSearchOffsets) do
			local newX, newY = nearX + (offset.x * range), nearY + (offset.y * range)

			-- Also check if any interactables are in the way
			local isInteractableInWay = false

			if (interactables) then
				for _, interactable in pairs(interactables) do
					if (interactable:isInPosition(newX, newY)) then
						isInteractableInWay = true
						break
					end
				end
			end

			if (not isInteractableInWay and not self:getWorld():isTileOccupied(newX, newY, nil, true)) then
				return newX, newY
			end
		end
	end

    return nil, nil
end

--- Plays a sound on the interactable
--- @param sound Source
function Interactable:playSound(sound)
    sound:play()
end

--- Checks if recently damaged
--- @return boolean, Interactable
function Interactable:recentlyDamaged()
	return self.nextDamagableAt and self.nextDamagableAt > love.timer.getTime(), self.lastDamagedBy
end

--- Check if the interactable is attacking
--- @return boolean, Interactable
function Interactable:attacking()
	if (not self.lastDamagedInteractable) then
		return false
	end

	local victim = self.lastDamagedInteractable

	return victim:recentlyDamaged(), victim
end

--- When an interactable is interacted with
--- @param deltaTime number
--- @param interactor Interactable
--- @return boolean # Whether the interactable was interacted with
function Interactable:updateInteract(deltaTime, interactor)
    if (not interactor:isOfType(Unit)) then
        print('Cannot interact with interactable as interactor is not a unit.')
        return false
    end

    local unitType = interactor:getUnitType()

    if (self.isRemoved) then
        if (unitType.damageStrength and self:canTakeDamageFrom(interactor)) then
            interactor:onInteractWithDestroyedInteractable(self)
        end

        return false
    end

    if (unitType.damageStrength and self:canTakeDamageFrom(interactor)) then
        if (self.nextDamagableAt and self.nextDamagableAt > love.timer.getTime()) then
            return false
        end

        self.nextDamagableAt = love.timer.getTime() + GameConfig.interactableDamageTimeInSeconds()
        self.lastDamagedBy = interactor
        interactor.lastDamagedInteractable = self

        if (self:damage(unitType.damageStrength, interactor)) then
            interactor:onInteractWithDestroyedInteractable(self)
        end

        return false
    end

    return true
end

--- Gets the sight range of the interactable in tiles for the fog of war
--- Due to us using tiles, its best to keep this as an even number
--- @return number
function Interactable:getSightRange()
	return self.sightRange
end

return Interactable
