--- @type BehaviorTreeTask
local TASK = {}

--[[
	e.g:
	self:createTask('FailIfNotEnoughResources', {
		-- The resources we need to create a barracks
		resources = StructureTypeRegistry:getStructureType('barracks').requiredResources,
	}),
--]]

--- @param player PlayerComputer
function TASK:run(player)
	self:debugPrint('FailIfNotEnoughResources', self.taskInfo.resourceGoal)

	self:fail()
end

return TASK
