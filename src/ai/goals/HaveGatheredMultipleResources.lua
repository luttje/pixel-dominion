--[[
	This works similar to HaveGatheredResources, but we can gather multiple resources at once.
	However where HaveGatheredResources forces all villagers to gather the same resource, this goal
	will split the resources among the villagers.
--]]

--- @type BehaviorGoal
local GOAL = {}

GOAL.requiresVillagers = true

--- Called when the goal is added to the goal list.
--- @param player PlayerComputer
function GOAL:init(player)
	local requirements = self.goalInfo.requirements

	assert(requirements and type(requirements) == 'table', 'Invalid requirements table')

	local resourceRequirements = {}

	assert(#requirements > 0, 'No requirements specified')

	local totalAmount = 0

	for _, requirement in ipairs(requirements) do
		assert(requirement.resourceTypeId, 'Invalid resource type id in requirement')

		local desiredAmount = requirement.desiredAmount

		if (type(desiredAmount) == 'function') then
			desiredAmount = desiredAmount()
		end

		desiredAmount = tonumber(desiredAmount)
		assert(desiredAmount, 'Invalid desiredAmount in requirement')

		local resourceType = ResourceTypeRegistry:getResourceType(requirement.resourceTypeId)
		assert(resourceType, 'Invalid resource type id: ' .. requirement.resourceTypeId)

		table.insert(resourceRequirements, {
			resourceType = resourceType,
			desiredAmount = desiredAmount
		})

		totalAmount = totalAmount + desiredAmount
	end

	self.goalInfo.resourceRequirements = resourceRequirements
	self.goalInfo.totalAmount = totalAmount
end

--- Returns a string representation of the goal
--- @return string
function GOAL:getInfoString()
	local faction = self.player:getFaction()
	local factionInventory = faction:getResourceInventory()
	local requirements = {}

	for _, requirement in ipairs(self.goalInfo.resourceRequirements) do
		table.insert(requirements, factionInventory:getValue(requirement.resourceType) .. '/' .. requirement.desiredAmount .. ' of ' .. requirement.resourceType.id)
	end

	return 'Gather ' .. table.concat(requirements, ' and ')
end

--- Called while the AI is working on the goal.
--- @param player PlayerComputer
--- @return boolean # Whether the goal has been completed
function GOAL:run(player)
    local faction = player:getFaction()

    -- local villagers = player:findIdleOrRandomUnits('villager', allResources / 10)
    local villagers = faction:getUnitsOfType('villager') -- Get all villagers for now

    assert(#villagers, 'No villager found')

	if (self:setVillagersToGatherResources(player, villagers)) then
		return true
	end

    return false
end

function GOAL:setVillagersToGatherResources(player, villagers)
    local faction = player:getFaction()
    local resourceRequirements = self.goalInfo.resourceRequirements
    local resourcesToStillGet = {}

    for _, requirement in ipairs(resourceRequirements) do
        local resourceType = requirement.resourceType

        if (not faction:getResourceInventory():has(resourceType.id, requirement.desiredAmount)) then
            table.insert(resourcesToStillGet, requirement)
        end
    end

    if (#resourcesToStillGet == 0) then
        -- We have all the resources we need
        return true
    end

    local villagersPerResource = math.ceil(#villagers / #resourcesToStillGet)

    for _, requirement in ipairs(resourcesToStillGet) do
        local resourceType = requirement.resourceType

        local villagersForThisResource = math.min(villagersPerResource, #villagers)

        for i = 1, villagersForThisResource do
            local villager = table.remove(villagers, 1)

            -- If they're already gathering the resource, we don't need to do anything
            local villagerInteractable = villager:getCurrentActionInteractable()
            local isGathering = villagerInteractable
                and villagerInteractable:isOfType(Resource)
                and villagerInteractable.resourceType == resourceType

            if (not isGathering) then
                -- Check if they're not on their way to the town hall with a full inventory
                if (villager:getResourceInventory():isFull()) then
                    local dropOffStructure = faction:getDropOffStructure(villager:getResourceInventory(), villager:getWorldPosition())

                    if (villagerInteractable ~= dropOffStructure) then
                        villager:commandTo(dropOffStructure.x, dropOffStructure.y, dropOffStructure)
                    end
                else
                    -- Put the villager to work
					local resource = villager:getWorld():findNearestResourceInstanceForFaction(
						faction,
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
                        -- TODO: For now we surrender, double-check if this is desired later
                        if (not structureTypeForResource) then
							faction:surrender()
							return false
						end

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
                                builders = { villager },
                            })
                        )
                    else
                        villager:commandTo(resource.x, resource.y, resource)
                    end
                end
            end
        end
    end
end

--- Called while other goals are being worked on, but we're in the goal list.
--- @param player PlayerComputer
--- @return boolean # Whether the goal has been completed
function GOAL:queuedUpdate(player)
    -- If all goals before us require no villagers and we have idle villagers, we should work on this goal
    local villagers = player:findIdleUnits('villager')

	if (#villagers == 0) then
		return false
	end

    local goalList = player:getGoalList()
	local goalIndex = table.IndexOf(goalList, self)

    for i = goalIndex - 1, 1, -1 do
        local goal = goalList[i]

        if (goal.requiresVillagers) then
            return false
        end
    end

	local villagerCount = #villagers

    -- No goals before us require villagers, so we can set those idle villagers to work
    if (self:setVillagersToGatherResources(player, villagers)) then
        self:debugPrint('All resources gathered! Generating new goals...')
        player:generateNewGoals()

        -- Returning true to remove this goal from the list
        return true
    else
        -- self:debugPrint("No goals before us require villagers, so we've set " .. villagerCount .. " villagers to gather resources!")
    end

	return false
end

return GOAL
