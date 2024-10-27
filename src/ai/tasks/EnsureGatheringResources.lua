--[[
	EnsureGatheringResources
--]]

local TASK = {}

--- @param data BehaviorTreeData
function TASK:start(data)
	local resourceGoal = self.taskInfo.resourceGoal

	if (type(self.taskInfo.resourceGoal) == 'function') then
        resourceGoal = self.taskInfo.resourceGoal()
	end

    if (resourceGoal) then
        if (resourceGoal:isOfType(StructureTypeRegistry.StructureRegistration)) then
            self.taskInfo.desiredResources = resourceGoal.requiredResources
        else
            assert(false, 'Invalid resource goal')
        end
    elseif (not self.taskInfo.desiredResources) then
        assert(false, 'No desired resources or goal specified')
    end
end

--- @param data BehaviorTreeData
function TASK:run(data)
	local resourceCount = 0

	for _, amount in pairs(self.taskInfo.desiredResources) do
		resourceCount = resourceCount + amount
	end

    if (resourceCount == 0) then
        print('No resources to gather')
        self:success()
		return
    end

    local player = data.player
    local faction = player:getFaction()
    local villagers = faction:getUnitsOfType('villager')
    local desiredResources = self.taskInfo.desiredResources
    local desiredResourcesKeys = table.Stack(table.Keys(self.taskInfo.desiredResources))
	local desiredResourceKey

    -- Send all villagers we have to gather our desired resources
    for _, villager in ipairs(villagers) do
        desiredResourceKey = desiredResourcesKeys:pop() or desiredResourceKey
		local desiredResource = desiredResources[desiredResourceKey]
		local desiredResourceType = ResourceTypeRegistry:getResourceType(desiredResourceKey)
        local villagerInteractable = villager:getCurrentActionInteractable()


        if (villagerInteractable and villagerInteractable:isOfType(Resource) and villagerInteractable.resourceType == desiredResourceType) then
        else
            -- If they have a full inventory, ensure they're heading back to the town hall
            if (villager:getResourceInventory():isFull()) then
                local townHall = faction:getTownHall()

                if (villagerInteractable ~= townHall) then
                    villager:commandTo(townHall.x, townHall.y, townHall)
                end
            else
				-- Start gathering wood from the nearest resource
				local resource = villager:getWorld():findNearestResourceInstance(desiredResourceType, villager.x,
					villager.y)

				if (not resource) then
					self:fail()
					return
				end

				villager:commandTo(resource.x, resource.y, resource)
			end
        end
    end

	print('EnsureGatheringResources for ' .. desiredResourceKey)
	self:success()
end

return TASK
