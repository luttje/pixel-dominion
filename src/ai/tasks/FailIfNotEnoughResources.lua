local TASK = {}

--[[
	e.g:
	self:createTask('FailIfNotEnoughResources', {
		-- The resources we need to create a barracks
		resources = StructureTypeRegistry:getStructureType('barracks').requiredResources,
	}),
--]]

--- @param data BehaviorTreeData
function TASK:run(data)
	print('FailIfNotEnoughResources', self.taskInfo.resourceGoal)

	self:fail()
end

return TASK
