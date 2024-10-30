local STRUCTURE = {}

STRUCTURE.id = 'town_hall'
STRUCTURE.name = 'Town Hall'

-- Don't allow construction of town halls for now
STRUCTURE.isInternal = true

STRUCTURE.imagePath = 'assets/images/structures/town-hall.png'

-- TODO: Have this config make the structure accept resources, instead of duplicating the code below in the updateInteract function (like its the same in lumber_camp now)
STRUCTURE.dropOffForResources = {
    wood = true,
    stone = true,
    food = true,
    gold = true,
}

--- @type UnitGenerationInfo[]
STRUCTURE.unitGenerationInfo = {
	{
		id = 'create_villager',
		text = 'Villager',
		icon = 'assets/images/icons/villager.png',
		unitTypeId = 'villager',
        generationTimeInSeconds = GameConfig.timeInSeconds(15),
        costs = {
			food = 25,
		}
	}
}

STRUCTURE.structureTilesetInfo = {
	-- Town Hall 1
	{
		-- Top of the town hall
		{
			tilesetId = 2,
			tileId = 517,
			targetLayer = 'Dynamic_Top',
			offsetX = 0,
			offsetY = -1,
		},
		{
			tilesetId = 2,
			tileId = 518,
			targetLayer = 'Dynamic_Top',
			offsetX = 1,
			offsetY = -1,
		},
		{
			tilesetId = 2,
			tileId = 519,
			targetLayer = 'Dynamic_Top',
			offsetX = 2,
			offsetY = -1,
		},
		-- Bottom of the town hall
		{
			tilesetId = 2,
			tileId = 617,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 0,
			offsetY = 0,
		},
		{
			tilesetId = 2,
			tileId = 618,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 1,
			offsetY = 0,
        },
		{
			tilesetId = 2,
			tileId = 619,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 2,
			offsetY = 0,
		},
    },
}

--- Called when the structure is created in the world
--- @param structure Structure
--- @param builders? Unit[]
function STRUCTURE:onSpawn(structure, builders)
	-- Start with 1 villager
    structure:generateUnit('villager')
end

--- When an structure is interacted with by a unit.
--- @param structure Structure
--- @param deltaTime number
--- @param interactor Interactable
--- @return boolean # Whether the interaction was successful, false stops the unit
function STRUCTURE:updateInteract(structure, deltaTime, interactor)
    local unitType = interactor:getUnitType()

	if (unitType.id ~= 'villager') then
        print('Unit cannot interact with the town hall.')
        return false
    end

    -- Take any resources from the unit and place them in the faction inventory
    local inventory = interactor:getResourceInventory()

    if (inventory:getCurrentResources() == 0) then
        return false
    end

    local faction = structure:getFaction()
    local factionInventory = faction:getResourceInventory()
    local lastResourceInstance = interactor:getLastResourceInstance()
	local world = faction:getWorld()

	assert(lastResourceInstance, 'No last resource instance found.')

    for resourceTypeId, resourceValue in pairs(inventory:getAll()) do
        factionInventory:add(resourceTypeId, resourceValue.value)
    end

    inventory:clear()

    -- First go back to the last resource we came from if it has any supply left
    if (lastResourceInstance:getSupply() > 0 and not lastResourceInstance.isRemoved) then
        interactor:commandTo(lastResourceInstance.x, lastResourceInstance.y, lastResourceInstance)

        return true
    end

	-- Find the nearest resource instance of the same type
    local nearestResourceInstance = world:findNearestResourceInstance(
        lastResourceInstance:getResourceType(),
        structure.x,
        structure.y,
		function(resource)
			local resourceFaction = resource:getFaction()

			if (faction and resourceFaction and resourceFaction ~= faction) then
				return false
			end

			return true
		end
	)

    if (not nearestResourceInstance) then
        return false
    end

    interactor:commandTo(nearestResourceInstance.x, nearestResourceInstance.y, nearestResourceInstance)

	return true
end

--- Returns whether the structure can be built by the faction. Resources are checked
--- before this function is called.
--- @param faction Faction
--- @return boolean
function STRUCTURE:canBeBuiltByFaction(faction)
	return false
end

return STRUCTURE
