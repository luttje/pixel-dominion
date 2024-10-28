--- @type BehaviorGoal
local GOAL = {}

--- Called when the goal is added to the goal list.
--- @param player PlayerComputer
function GOAL:init(player)
    local unitTypeId = self.goalInfo.unitTypeId

    if (type(unitTypeId) == 'function') then
        unitTypeId = unitTypeId()
    end

    local amount = self.goalInfo.amount

	if (type(amount) == 'function') then
		amount = amount()
	end

	amount = tonumber(amount)

	assert(amount, 'Invalid amount')

	assert(self.goalInfo.structureType, 'Missing structure type')
	assert(self.goalInfo.structureType:isOfType(StructureTypeRegistry.StructureRegistration), 'Invalid structure type')

    self.goalInfo.unitTypeId = unitTypeId
	self.goalInfo.amount = amount
end

--- Returns a string representation of the goal
--- @return string
function GOAL:getInfoString()
	return 'Have ' .. self.goalInfo.amount .. ' of ' .. self.goalInfo.unitTypeId
end

--- Called while the AI is working on the goal.
--- @param player PlayerComputer
--- @return boolean # Whether the goal has been completed
function GOAL:run(player)
	local faction = player:getFaction()
	local unitTypeId = self.goalInfo.unitTypeId
	local amount = self.goalInfo.amount
	local structureType = self.goalInfo.structureType

	local units = faction:getUnitsOfType(unitTypeId)

	-- If we have reached the desired amount of units, we're done
	if (#units >= amount) then
		return true
	end

	local structure = faction:getStructuresOfType(structureType)[1]

	-- If we don't have the structure that will give us the units, we need to build it
	if (not structure) then
		player:prependGoal(
			player:createGoal('BuildStructure', {
				structureTypeId = structureType.id,
			})
		)
		return false
	end

	local unitGenerationInfo = structure:getStructureType():getUnitGenerationInfo(unitTypeId)

	assert(unitGenerationInfo, 'Failed to get unit generation info for id ' .. tostring(unitTypeId))

	local resourcesNeeded = unitGenerationInfo.costs
	local hasResources = true

	-- Check if we have enough resources to create a new unit
	for resourceTypeId, amount in pairs(resourcesNeeded) do
		if (not faction:getResourceInventory():has(resourceTypeId, amount)) then
			player:prependGoal(
				player:createGoal('GatherResources', {
					resourceTypeId = resourceTypeId,
					amount = amount,
				})
			)
			hasResources = false
		end
	end

	-- We don't have the resources, so we've scheduled the gathering of them
	if (not hasResources) then
		return false
	end

	-- We have the resources, but do we have the housing?
	local housing = faction:getResourceInventory():getValue('housing')

	-- We try creating one unit at a time, since this goal will be called again
    if (#units + amount > housing) then
        player:prependGoal(
            player:createGoal('BuildStructure', {
                structureTypeId = 'house',
            })
        )

		return false
    end

    if (structure:isUnitInGenerationQueue(unitTypeId)) then
        -- We're already generating a unit
        return false
    end

	-- Shouldn't fail, since we checked if we could generate the unit
    assert(structure:enqueueUnitGeneration(unitGenerationInfo), 'Structure cannot generate unit')

	return false
end

return GOAL
