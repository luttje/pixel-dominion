--- @type Directive
local DIRECTIVE = {}

--- Called when the directive is added to the directive list.
--- @param player PlayerComputer
function DIRECTIVE:init(player)
    local unitTypeId = self.directiveInfo.unitTypeId

    if (type(unitTypeId) == 'function') then
        unitTypeId = unitTypeId()
    end

    local amount = self.directiveInfo.amount

	if (type(amount) == 'function') then
		amount = amount()
	end

	amount = tonumber(amount)

	assert(amount, 'Invalid amount')

	assert(self.directiveInfo.structureType, 'Missing structure type')
	assert(self.directiveInfo.structureType:isOfType(StructureTypeRegistry.StructureRegistration), 'Invalid structure type')

    self.directiveInfo.unitTypeId = unitTypeId
	self.directiveInfo.amount = amount
end

--- Returns a string representation of the directive
--- @return string
function DIRECTIVE:getInfoString()
	return 'Have ' .. self.directiveInfo.amount .. ' of ' .. self.directiveInfo.unitTypeId
end

--- Called while the AI is working on the directive.
--- @param player PlayerComputer
--- @return boolean # Whether the directive has been completed
function DIRECTIVE:run(player)
	local faction = player:getFaction()
	local unitTypeId = self.directiveInfo.unitTypeId
	local amount = self.directiveInfo.amount
	local structureType = self.directiveInfo.structureType

	local units = faction:getUnitsOfType(unitTypeId)

	-- If we have reached the desired amount of units, we're done
	if (#units >= amount) then
		return true
	end

	local structure = faction:getStructuresOfType(structureType)[1]

	-- If we don't have the structure that will give us the units, we need to build it
	if (not structure) then
		player:prependDirective(
			player:createDirective('BuildStructure', {
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
			player:prependDirective(
				player:createDirective('HaveGatheredResources', {
					resourceTypeId = resourceTypeId,
					desiredAmount = amount,
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

	-- We try creating one unit at a time, since this directive will be called again
    if (#units + amount > housing) then
        player:prependDirective(
            player:createDirective('BuildStructure', {
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

return DIRECTIVE
