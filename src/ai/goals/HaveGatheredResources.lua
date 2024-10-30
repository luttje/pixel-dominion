--- @type BehaviorGoal
local GOAL = {}

GOAL.requiresVillagers = true

--- Called when the goal is added to the goal list.
--- @param player PlayerComputer
function GOAL:init(player)
    local resourceTypeId = self.goalInfo.resourceTypeId
    local desiredAmount = self.goalInfo.desiredAmount

    if (type(desiredAmount) == 'function') then
        desiredAmount = desiredAmount()
    end

    desiredAmount = tonumber(desiredAmount)

	assert(resourceTypeId, 'Invalid resource type id')
	assert(desiredAmount, 'Invalid desiredAmount')

    local resourceType = ResourceTypeRegistry:getResourceType(resourceTypeId)

	assert(resourceType, 'Invalid resource type id')

	self.goalInfo.resourceType = resourceType
    self.goalInfo.desiredAmount = desiredAmount
end

--- Returns a string representation of the goal
--- @return string
function GOAL:getInfoString()
	return 'Gather ' .. self.goalInfo.desiredAmount .. ' of ' .. self.goalInfo.resourceType.id
end

--- Called while the AI is working on the goal.
--- @param player PlayerComputer
--- @return boolean # Whether the goal has been completed
function GOAL:run(player)
    local faction = player:getFaction()
    local resourceType = self.goalInfo.resourceType
    local desiredAmount = self.goalInfo.desiredAmount

    if (faction:getResourceInventory():has(resourceType.id, desiredAmount)) then
        return true
    end

    local villagers = player:findIdleOrRandomUnits('villager', desiredAmount / 10)

	assert(#villagers, 'No villager found')

	-- Send all our idle units (or some random units, increasing by the desiredAmount) to gather the resource
	for _, villager in ipairs(villagers) do
        -- If they're already gathering the resource, we don't need to do anything
        local villagerInteractable = villager:getCurrentActionInteractable()
		local isGathering = villagerInteractable and villagerInteractable:isOfType(Resource) and villagerInteractable.resourceType == resourceType

        if (not isGathering) then
            -- Check if they're not on their way to the town hall with a full inventory
			if (villager:getResourceInventory():isFull()) then
				local dropOffStructure = faction:getDropOffStructure(villager:getResourceInventory(), villager:getWorldPosition())

				if (villagerInteractable ~= dropOffStructure) then
					villager:commandTo(dropOffStructure.x, dropOffStructure.y, dropOffStructure)
				end
			else
				-- Put the villager to work
				local resource = villager:getWorld():findNearestResourceInstance(
					resourceType,
					villager.x,
					villager.y,
					function(resource)
						local resourceFaction = resource:getFaction()

						if (resourceFaction and resourceFaction ~= faction) then
							return false
						end

						return true
					end)

				-- If there's no resource in the world, we find a structure that has the resource, like the farmland:
				if (not resource) then
					local structureTypeForResource

					for _, structureType in ipairs(StructureTypeRegistry:getAllStructureTypes()) do
						if (structureType.spawnsResources and structureType.spawnsResources[resourceType.id] and structureType.spawnsResources[resourceType.id] > 0) then
							structureTypeForResource = structureType
							break
						end
					end

					-- TODO: How do we get the resource, if none are in the world and we don't have a structure that spawns them?
					-- TODO: Should the AI surrender?
					assert(structureTypeForResource, 'No structure type found for resource type')

					local structuresToBeBuilt = player:countGoals('BuildStructure', {
						structureTypeId = structureTypeForResource.id,
					})

					-- Don't queue up more than 3 structures to be built for this
					if (structuresToBeBuilt >= 3) then
						return false
					end

					-- Add a goal to build the structure that spawns the resource
					player:prependGoal(
						player:createGoal('BuildStructure', {
							structureTypeId = structureTypeForResource.id,
							builders = {villager},
						})
					)
				else
					villager:commandTo(resource.x, resource.y, resource)
				end
			end
		end
	end

    -- We're not done yet
    return false
end

return GOAL
