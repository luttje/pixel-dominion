--[[
	This works similar to HaveGatheredResources, but we can gather multiple resources at once.
	However where HaveGatheredResources forces all villagers to gather the same resource, this directive
	will split the resources among the villagers.
--]]

--- @type Directive
local DIRECTIVE = {}

DIRECTIVE.requiresVillagers = true

--- Called when the directive is added to the directive list.
--- @param player PlayerComputer
function DIRECTIVE:init(player)
	local requirements = self.directiveInfo.requirements

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

	self.directiveInfo.resourceRequirements = resourceRequirements
	self.directiveInfo.totalAmount = totalAmount
end

--- Returns a string representation of the directive
--- @return string
function DIRECTIVE:getInfoString()
	local faction = self.player:getFaction()
	local factionInventory = faction:getResourceInventory()
	local requirements = {}

	for _, requirement in ipairs(self.directiveInfo.resourceRequirements) do
		table.insert(requirements, factionInventory:getValue(requirement.resourceType) .. '/' .. requirement.desiredAmount .. ' of ' .. requirement.resourceType.id)
	end

	return 'Gather ' .. table.concat(requirements, ' and ')
end

--- Called while the AI is working on the directive.
--- @param player PlayerComputer
--- @return boolean # Whether the directive has been completed
function DIRECTIVE:run(player)
    local faction = player:getFaction()

    -- local villagers = player:findIdleOrRandomUnits('villager', allResources / 10)
    local villagers = faction:getUnitsOfType('villager') -- Get all villagers for now

    assert(#villagers, 'No villager found')

	if (self:setVillagersToGatherResources(player, villagers)) then
		return true
	end

    return false
end

function DIRECTIVE:setVillagersToGatherResources(player, villagers)
    local faction = player:getFaction()
    local resourceRequirements = self.directiveInfo.resourceRequirements
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

--- Called while other directives are being worked on, but we're in the directive list.
--- @param player PlayerComputer
--- @return boolean # Whether the directive has been completed
function DIRECTIVE:queuedUpdate(player)
    -- If all directives before us require no villagers and we have idle villagers, we should work on this directive
    local villagers = player:findIdleUnits('villager')

	if (#villagers == 0) then
		return false
	end

    local directiveList = player:getDirectiveList()
	local directiveIndex = table.IndexOf(directiveList, self)

    for i = directiveIndex - 1, 1, -1 do
        local directive = directiveList[i]

        if (directive.requiresVillagers) then
            return false
        end
    end

	local villagerCount = #villagers

    -- No directives before us require villagers, so we can set those idle villagers to work
    if (self:setVillagersToGatherResources(player, villagers)) then
        self:debugPrint('All resources gathered! Generating new directives...')
        player:generateNewDirectives()

        -- Returning true to remove this directive from the list
        return true
    else
        -- self:debugPrint("No directives before us require villagers, so we've set " .. villagerCount .. " villagers to gather resources!")
    end

	return false
end

return DIRECTIVE
