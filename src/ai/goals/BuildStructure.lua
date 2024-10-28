--- @type BehaviorGoal
local GOAL = {}

--- Called when the goal is added to the goal list.
--- @param player PlayerComputer
function GOAL:init(player)
	local structureTypeId = self.goalInfo.structureTypeId

	if (type(structureTypeId) == 'function') then
		structureTypeId = structureTypeId()
	end

	assert(structureTypeId, 'Invalid structure type id')

    local structureType = StructureTypeRegistry:getStructureType(structureTypeId)

	assert(structureType, 'Invalid structure type id')

	self.goalInfo.structureType = structureType
end

--- Returns a string representation of the goal
--- @return string
function GOAL:getInfoString()
	return 'Build ' .. self.goalInfo.structureType.id
end

--- Called while the AI is working on the goal.
--- @param player PlayerComputer
--- @return boolean # Whether the goal has been completed
function GOAL:run(player)
    local faction = player:getFaction()
    local structureType = self.goalInfo.structureType

	-- If we can't build this structure because we don't have the resources, add a goal to get the resources
    if (not structureType:canBeBuilt(faction)) then
        for resourceTypeId, amount in pairs(structureType.requiredResources) do
            if (not faction:getResourceInventory():has(resourceTypeId, amount)) then
                player:prependGoal(
                    player:createGoal('GatherResources', {
                        resourceTypeId = resourceTypeId,
                        amount = amount,
                    })
                )
            end
        end

		return false
    end

    local villagers = player:findIdleUnitsOrRandomUnit('villager')

	if (#villagers == 0) then
		-- If we don't have a villager, ensure we generate one
		player:prependGoal(
			player:createGoal('HaveUnitsOfType', {
				unitTypeId = 'villager',
				structureType = StructureTypeRegistry:getStructureType('town_hall'),
				amount = 1,
			})
		)

		return false
	end

	local x, y = faction:findSuitableLocationToBuild(structureType)

	assert(x and y, 'No suitable location to build')

    faction:spawnStructure(structureType, x, y, villagers, isFree)
	self:debugPrint('Building structure with ' .. #villagers .. ' villagers')

	return true
end

return GOAL
