local SpeechLog = require('libraries.SpeechLog')

--- Clear constant to show that placement is free
FORCE_FREE_PLACEMENT = true

--- Represents a faction in the game
--- @class Faction
---
--- @field factionType FactionTypeRegistry.FactionRegistration
--- @field color table
--- @field colorHighlight table
--- @field world World|nil
--- @field player Player
---
--- @field resourceInventory ResourceInventory
--- @field units table<number, Unit> # The units in the world
--- @field structures table<number, Structure> # The structures in the world
--- @field fogOfWarMap table<number, table<number, boolean>> # The fog of war map
--- @field speechLog SpeechLog
local Faction = DeclareClass('Faction')

--- Initializes the faction
--- @param config table
function Faction:initialize(config)
    assert(config.factionType, 'Faction must have a faction type.')
	assert(config.player, 'Faction must have a player.')
	assert(config.color, 'Faction must have a color.')

	self.resourceInventory = ResourceInventory({
		withDefaultValues = true,
	})
	self.units = {}
	self.structures = {}

    table.Merge(self, config)

	self.speechLog = SpeechLog()

    -- If there's no highlight color, use a brighter version of the color
    if (not self.colorHighlight) then
        self.colorHighlight = {
            math.min(self.color[1] + 0.5, 1),
            math.min(self.color[2] + 0.5, 1),
            math.min(self.color[3] + 0.5, 1),
        }
    end

    self.player:setFaction(self)
end

--- Sets the world for the faction
--- @param world World
function Faction:setWorld(world)
    self.world = world
    self.player:setWorld(self.world)

	self.fogOfWarMap = self.world:createFogOfWarMap(self)
end

--- Gets the world for the faction
--- @return World
function Faction:getWorld()
	return self.world
end

--- Gets the player for the faction
--- @return Player
function Faction:getPlayer()
	return self.player
end

--- Gets the resource inventory
--- @return ResourceInventory
function Faction:getResourceInventory()
	return self.resourceInventory
end

--- Gets the type of faction
--- @return FactionTypeRegistry.FactionRegistration
function Faction:getFactionType()
    return self.factionType
end

--- Gets the faction's color
--- @return table, table # The color and highlight color
function Faction:getColors()
	return table.Copy(self.color), table.Copy(self.colorHighlight)
end

--- Says the given message
--- @param message string
function Faction:say(message)
	self.speechLog:addSpeech(message)
end

--- Spawns a unit of the given type at the given position
--- @param unitType UnitTypeRegistry.UnitRegistration
--- @param x number
--- @param y number
--- @return Unit
function Faction:spawnUnit(unitType, x, y)
	local unit = Unit({
        unitType = unitType,
		faction = self,
		x = x,
		y = y,
		targetX = x,
		targetY = y,
        health = 100,
		world = self:getWorld(),
    })

	unit:onSpawn()

	table.insert(self.units, unit)

	return unit
end

--- Returns all units
--- @return Unit[]
function Faction:getUnits()
    return self.units
end

--- Returns all units near the given position
--- @param x number
--- @param y number
--- @param searchRange number
--- @return Unit[]
function Faction:getUnitsNear(x, y, searchRange)
    local localRange = GameConfig.tileSearchOffsetsBoundary
	local range = {
		x = x + (localRange.x * searchRange),
		y = y + (localRange.y * searchRange),
		width = localRange.width * searchRange,
		height = localRange.height * searchRange,
	}

    local nearbyUnits = self:getWorld().searchTree:query(range)

	return nearbyUnits
end

--- Returns all units of the given type
--- @param unitType UnitTypeRegistry.UnitRegistration|string
--- @return Unit[]
function Faction:getUnitsOfType(unitType)
	local units = {}

	for _, unit in ipairs(self.units) do
		if (unit.unitType.id == unitType or unit.unitType == unitType) then
			table.insert(units, unit)
		end
	end

	return units
end

--- Removes the unit from the faction
--- @param unit Unit
--- @return boolean # Whether the unit was removed
function Faction:removeUnit(unit)
	for i, factionUnit in ipairs(self.units) do
		if (factionUnit == unit) then
			table.remove(self.units, i)

			return true
		end
	end

	return false
end

--- Spawns a structure of the given type at the given position
--- @param structureType StructureTypeRegistry.StructureRegistration
--- @param x number
--- @param y number
--- @param builders? Unit[]
--- @param isFree? boolean
--- @return Structure
function Faction:spawnStructure(structureType, x, y, builders, isFree)
    assert(structureType.id == 'town_hall' or #self.structures > 0, 'Town hall must be spawned first.')

    if (not isFree) then
        structureType:subtractResources(self)
    end

    local structure = structureType:spawnAtTile(self:getWorld(), self, x, y, builders)

    table.insert(self.structures, structure)

    return structure
end

--- Finds a suitable location to build the structure, by scanning outward from the town hall
--- @param structureType StructureTypeRegistry.StructureRegistration
--- @param withRandomOffset? boolean
--- @return number, number
function Faction:findSuitableLocationToBuild(structureType, withRandomOffset)
	for range = 1, math.huge do
        for _, offset in pairs(GameConfig.tileSearchOffsets) do
            local newX, newY = self:getTownHall().x + (offset.x * range), self:getTownHall().y + (offset.y * range)

            -- By adding a bit of random offset the village won't look so uniform
			if (withRandomOffset) then
				newX = newX + math.random(-4, 4)
				newY = newY + math.random(-4, 4)
			end

			if (structureType:canPlaceAt(self:getWorld(), newX, newY)) then
				return newX, newY
			end
		end

		if (range > 1000) then
			-- Prevent infinite loop
			print('findSuitableLocationToBuild - No location found to target, stopping.')
			break
		end
	end

	assert(false, 'No suitable location to build structure')
end

--- Returns all structures
--- @return Structure[]
function Faction:getStructures()
	return self.structures
end

--- Removes the structure from the faction
--- @param structure Structure
--- @return boolean # Whether the structure was removed
function Faction:removeStructure(structure)
	for i, factionStructure in ipairs(self.structures) do
		if (factionStructure == structure) then
			table.remove(self.structures, i)

			self:onStructureRemoved(structure)

			return true
		end
	end

	return false
end

--- Returns all structures of the given type
--- @param structureType StructureTypeRegistry.StructureRegistration|string
--- @return Structure[]
function Faction:getStructuresOfType(structureType)
	local structures = {}

	for _, structure in ipairs(self.structures) do
		if (structure.structureType.id == structureType or structure.structureType == structureType) then
			table.insert(structures, structure)
		end
	end

	return structures
end

--- Gets the town hall, always the first structure
--- @return Structure?
function Faction:getTownHall()
	local structure = self:getStructures()[1]

	if (not structure or structure.structureType.id ~= 'town_hall') then
		return nil
	end

	return structure
end

--- Called to perform logic on the faction
--- @param deltaTime number
function Faction:update(deltaTime)
	for _, unit in ipairs(self.units) do
		unit:update(deltaTime)
	end

	for _, structure in ipairs(self.structures) do
		structure:update(deltaTime)
	end
end

--- Returns both units and structures
--- @return table<number, Unit|Structure>
function Faction:getInteractables()
    local interactables = {}

    for _, unit in ipairs(self.units) do
        table.insert(interactables, unit)
    end

    for _, structure in ipairs(self.structures) do
        table.insert(interactables, structure)
    end

    return interactables
end

--- Returns the available structures for the faction
--- @return StructureTypeRegistry.StructureRegistration[]
function Faction:getAvailableStructures()
    local availableStructures = {}

    for _, structureType in pairs(StructureTypeRegistry:getAllStructureTypes()) do
        if (not structureType.isInternal) then
            table.insert(availableStructures, structureType)
        end
    end

    return availableStructures
end

--- Returns the units currently attacking the faction
--- @return Interactable[]
function Faction:getAttackingUnits()
    local attackers = {}

    for i, structure in ipairs(self:getInteractables()) do
        local recentlyDamaged, damagedBy = structure:recentlyDamaged()

        if (recentlyDamaged) then
            table.insert(attackers, damagedBy)
        end
    end

    return attackers
end

--- Goes through all structures and checks their types to see if resources can be dropped off there
--- @param resourceInventory ResourceInventory
--- @param nearX? number
--- @param nearY? number
--- @return Structure
function Faction:getDropOffStructure(resourceInventory, nearX, nearY)
    local matchedStructures = {
        self:getTownHall()
    }

    local nearestStructure
    local nearestDistance = math.huge

    for _, structure in ipairs(self.structures) do
        if (structure.structureType.dropOffForResources) then
            local matchesAll = true

            for resourceTypeId, resourceValue in pairs(resourceInventory:getAll()) do
                local resourceType = ResourceTypeRegistry:getResourceType(resourceTypeId)
                local acceptsResource = structure.structureType.dropOffForResources[resourceType.id]

                if (not acceptsResource) then
                    matchesAll = false
                    break
                end
            end

            if (matchesAll) then
                table.insert(matchedStructures, structure)

                if (nearX and nearY) then
                    local distance = structure:getDistanceTo(nearX, nearY)

                    if (distance < nearestDistance) then
                        nearestStructure = structure
                        nearestDistance = distance
                    end
                end
            end
        end
    end

    if (nearestStructure) then
        return nearestStructure
    end

    return table.Random(matchedStructures)
end

--- Removes the faction and all its units and structures
function Faction:remove()
    for i = #self.units, 1, -1 do
        self.units[i]:remove()
    end

    for i = #self.structures, 1, -1 do
        self.structures[i]:remove()
    end

    self.world:removeFaction(self)
	self.isDefeated = true
end

--- Checks if we should just surrender, because we're nearly dead
--- @return boolean
function Faction:shouldSurrender()
	local units = self:getUnits()
	local resourceInventory = self:getResourceInventory()
    local townHall = self:getTownHall()
	local generationInfo = townHall and townHall.structureType:getUnitGenerationInfo('villager')
    local canGenerateVillager = generationInfo and resourceInventory:hasCosts(generationInfo.costs)

	-- No chance to recover if we have no town hall or no units and can't generate a villager
    if (not townHall or (not canGenerateVillager and #units == 0)) then
        return true
    end

	if (self.factionType.checkShouldSurrender) then
		local shouldSurrender = self.factionType:checkShouldSurrender(self)

		if (shouldSurrender) then
			return true
		end
	end

	return false
end

--- Surrenders, calls onSurrender on the type to give a final speech
function Faction:surrender()
    if (self.factionType.onSurrender) then
        local speech = self.factionType:onSurrender(self)

        if (speech) then
            self:say(table.Random(speech))
        end
    end

    self:remove()
end

--- Called when an interactable moves, so we can update the fog of war
--- @param interactable Interactable
function Faction:onInteractableMoved(interactable)
    local sightRange = interactable:getSightRange()

	if (sightRange == 0) then
		return
	end

	local x, y = interactable.x, interactable.y

	self:getWorld():revealFogOfWar(self, self.fogOfWarMap, x, y, sightRange * .5)
end

--- Called when a computer player completes a behavior directive
--- @param directive Directive
function Faction:onBehaviorDirectiveCompleted(directive)
	if (GameConfig.aiAnnounceRawDirectiveCompletion) then
		self:say('Directive completed: ' .. currentDirective:getInfoString())
		return
	end

	if (self.factionType.onDirectiveCompleted) then
		local speech = self.factionType:onDirectiveCompleted(self, directive)

		if (speech) then
			self:say(table.Random(speech))
		end
	end

	if (not self.factionType.directiveSpeeches) then
		return
	end

	-- See if the faction has a speech for the directive
	local speech = self.factionType.directiveSpeeches[directive.id]

	if (speech) then
		self:say(table.Random(speech))
	end
end

--- Called when a structure is removed
--- @param structure Structure
function Faction:onStructureRemoved(structure)
end

return Faction
