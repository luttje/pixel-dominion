--[[
	This works similar to GatherResources, but we can gather multiple resources at once.
	However where GatherResources forces all villagers to gather the same resource, this goal
	will split the resources among the villagers.
--]]

--- @type BehaviorGoal
local GOAL = {}

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

		local amount = requirement.amount

		if (type(amount) == 'function') then
			amount = amount()
		end

		amount = tonumber(amount)
		assert(amount, 'Invalid amount in requirement')

		local resourceType = ResourceTypeRegistry:getResourceType(requirement.resourceTypeId)
		assert(resourceType, 'Invalid resource type id: ' .. requirement.resourceTypeId)

		table.insert(resourceRequirements, {
			resourceType = resourceType,
			amount = amount
		})

		totalAmount = totalAmount + amount
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
		table.insert(requirements, factionInventory:getValue(requirement.resourceType) .. '/' .. requirement.amount .. ' of ' .. requirement.resourceType.id)
	end

	return 'Gather ' .. table.concat(requirements, ' and ')
end

--- Called while the AI is working on the goal.
--- @param player PlayerComputer
--- @return boolean # Whether the goal has been completed
function GOAL:run(player)
	local faction = player:getFaction()
	local resourceRequirements = self.goalInfo.resourceRequirements

	-- local villagers = player:findIdleOrRandomUnits('villager', allResources / 10)
	local villagers = faction:getUnitsOfType('villager') -- Get all villagers for now

	assert(#villagers, 'No villager found')

	local villagersPerResource = math.ceil(#villagers / #resourceRequirements)
	local setVillagersToWork = false

	for _, requirement in ipairs(resourceRequirements) do
		local resourceType = requirement.resourceType

		if (not faction:getResourceInventory():has(resourceType.id, requirement.amount)) then
			setVillagersToWork = true
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
						local townHall = faction:getTownHall()

						if (villagerInteractable ~= townHall) then
							villager:commandTo(townHall.x, townHall.y, townHall)
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
		end
	end

	-- If we didn't set any villagers to work, we must have gathered all resources
	if (not setVillagersToWork) then
		return true
	end

	return false
end

return GOAL
