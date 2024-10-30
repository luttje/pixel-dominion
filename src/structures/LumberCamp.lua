local STRUCTURE = {}

STRUCTURE.id = 'lumber_camp'
STRUCTURE.name = 'Lumber Camp'

STRUCTURE.imagePath = 'assets/images/structures/lumber-camp.png'
STRUCTURE.requiredResources = {
	wood = 50,
    stone = 10,
}

-- TODO: Have this config make the structure accept resources, instead of duplicating the code below in the updateInteract function (like its the same in town_hall now)
STRUCTURE.dropOffForResources = {
	wood = true,
}

-- --- @type UnitGenerationInfo[]
-- STRUCTURE.unitGenerationInfo = {
-- 	{
-- 		id = 'create_lumberjack',
-- 		text = 'Lumberjack',
-- 		icon = 'assets/images/icons/lumberjack.png',
-- 		unitTypeId = 'lumberjack',
-- 		generationTimeInSeconds = GameConfig.timeInSeconds(15),
-- 		costs = {
--			food = 25,
-- 		}
-- 	}
-- }

STRUCTURE.structureTilesetInfo = {
	-- Lumber Camp 1
	{
		-- Top of the lumber camp
		{
			tilesetId = 2,
			tileId = 1115,
			targetLayer = 'Dynamic_Top',
			offsetX = 0,
			offsetY = -1,
		},
		{
			tilesetId = 2,
			tileId = 1116,
			targetLayer = 'Dynamic_Top',
			offsetX = 1,
			offsetY = -1,
		},
		-- Bottom of the lumber camp
		{
			tilesetId = 2,
			tileId = 1215,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 0,
			offsetY = 0,
		},
		{
			tilesetId = 2,
			tileId = 1216,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 1,
			offsetY = 0,
		},
	},
}

--- Called when the structure is created in the world
--- @param structure Structure
--- @param builders? Unit[]
function STRUCTURE:onSpawn(structure, builders)
    if (not builders) then
        return
    end

	local world = structure:getWorld()
	local nearestResourceInstance = world:findNearestResourceInstance(
		ResourceTypeRegistry:getResourceType('wood'),
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
		return
	end

    -- Have the builders start harvesting the resource
    for _, builder in ipairs(builders) do
		builder:commandTo(nearestResourceInstance.x, nearestResourceInstance.y, nearestResourceInstance)
	end
end

--- When an structure is interacted with by a unit.
--- @param structure Structure
--- @param deltaTime number
--- @param interactor Interactable
--- @return boolean # Whether the interaction was successful, false stops the unit
function STRUCTURE:updateInteract(structure, deltaTime, interactor)
	local unitType = interactor:getUnitType()

	if (unitType.id ~= 'lumberjack' and unitType.id ~= 'villager') then
		print('Unit cannot interact with the lumber camp.', unitType.id)
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
    return true
end

return STRUCTURE
