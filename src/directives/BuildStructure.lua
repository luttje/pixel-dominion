--- @type Directive
local DIRECTIVE = {}

DIRECTIVE.requiresVillagers = true

--- Called when the directive is added to the directive list.
--- @param player PlayerComputer
function DIRECTIVE:init(player)
	local structureTypeId = self.directiveInfo.structureTypeId

	if (type(structureTypeId) == 'function') then
		structureTypeId = structureTypeId()
	end

	assert(structureTypeId, 'Invalid structure type id')

    local structureType = StructureTypeRegistry:getStructureType(structureTypeId)

	assert(structureType, 'Invalid structure type id')

	self.directiveInfo.structureType = structureType
end

--- Returns a string representation of the directive
--- @return string
function DIRECTIVE:getInfoString()
	return 'Build ' .. self.directiveInfo.structureType.id
end

--- Called while the AI is working on the directive.
--- @param player PlayerComputer
--- @return boolean # Whether the directive has been completed
function DIRECTIVE:run(player)
    local faction = player:getFaction()
    local structureType = self.directiveInfo.structureType

	-- If we can't build this structure because we don't have the resources, add a directive to get the resources
    if (not structureType:canBeBuilt(faction)) then
        for resourceTypeId, amount in pairs(structureType.requiredResources) do
            if (not faction:getResourceInventory():has(resourceTypeId, amount)) then
                player:prependDirective(
                    player:createDirective('HaveGatheredResources', {
                        resourceTypeId = resourceTypeId,
                        desiredAmount = amount,
                    })
                )
            end
        end

		return false
    end

    local villagers = self.directiveInfo.builders or player:findIdleOrRandomUnits('villager')

	if (#villagers == 0) then
		-- If we don't have a villager, ensure we generate one
		player:prependDirective(
			player:createDirective('HaveUnitsOfType', {
				unitTypeId = 'villager',
				structureType = StructureTypeRegistry:getStructureType('town_hall'),
				amount = 1,
			})
		)

		return false
	end

	local x, y = faction:findSuitableLocationToBuild(structureType, true)

	assert(x and y, 'No suitable location to build')

    faction:spawnStructure(structureType, x, y, villagers, isFree)

	return true
end

return DIRECTIVE
