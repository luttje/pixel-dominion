--- @type BehaviorTreeTask
local TASK = {}

--- @param player PlayerComputer
function TASK:start(player)
    local structureType = self.taskInfo.structureType

    if (type(self.taskInfo.structureType) == 'function') then
        structureType = self.taskInfo.structureType()
    end

	assert(structureType, 'No desired structure to build specified')

	self.taskInfo.structureType = structureType
end

--- @param player PlayerComputer
function TASK:run(player)
    local faction = player:getFaction()
	local structureType = self.taskInfo.structureType

	-- Check if we have enough resources to build the structure
    if (not structureType:canBeBuilt(faction)) then
        self:fail()
        return
    end

    -- Find a suitable location to build the structure
    local x, y = faction:findSuitableLocationToBuild(structureType)

	if (not x or not y) then
		self:debugPrint('No suitable location to build structure', structureType.id)
		self:fail()
		return
	end

    -- Find a villager that can build the structure
    local villager = self.player:findIdleOrRandomUnit('villager')

	if (not villager) then
		self:debugPrint('No idle villagers to build structure', structureType.id)
		self:fail()
		return
	end

	-- Build the structure
	faction:spawnStructure(structureType, x, y, {villager})
	self:success()
end

return TASK
