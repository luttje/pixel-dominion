--- @type Directive
local DIRECTIVE = {}

DIRECTIVE.requiresVillagers = true

--- Called when the directive is added to the directive list.
--- @param player PlayerComputer
function DIRECTIVE:init(player)
    local resourceTypeId = self.directiveInfo.resourceTypeId
    local desiredAmount = self.directiveInfo.desiredAmount

    if (type(desiredAmount) == 'function') then
        desiredAmount = desiredAmount()
    end

    desiredAmount = tonumber(desiredAmount)

	assert(resourceTypeId, 'Invalid resource type id')
	assert(desiredAmount, 'Invalid desiredAmount')

    local resourceType = ResourceTypeRegistry:getResourceType(resourceTypeId)

	assert(resourceType, 'Invalid resource type id')

	self.directiveInfo.resourceType = resourceType
    self.directiveInfo.desiredAmount = desiredAmount
end

--- Returns a string representation of the directive
--- @return string
function DIRECTIVE:getInfoString()
	return 'Gather ' .. self.directiveInfo.desiredAmount .. ' of ' .. self.directiveInfo.resourceType.id
end

--- Called while the AI is working on the directive.
--- @param player PlayerComputer
--- @return boolean # Whether the directive has been completed
function DIRECTIVE:run(player)
    local faction = player:getFaction()
    local resourceType = self.directiveInfo.resourceType
    local desiredAmount = self.directiveInfo.desiredAmount

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

					local structuresToBeBuilt = player:countDirectives('BuildStructure', {
						structureTypeId = structureTypeForResource.id,
					})

					-- Don't queue up more than 3 structures to be built for this
					if (structuresToBeBuilt >= 3) then
						return false
					end

					-- Add a directive to build the structure that spawns the resource
					player:prependDirective(
						player:createDirective('BuildStructure', {
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

return DIRECTIVE
