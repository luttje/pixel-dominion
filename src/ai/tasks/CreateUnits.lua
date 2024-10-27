--[[
	This task will create units, like villagers at the town hall or soldiers at the barracks, e.g:

	-- If we have barracks, create soldiers
	self:createTask('CreateUnits', {
		unitType = UnitTypeRegistry:getUnitType('soldier'),
		structureType = StructureTypeRegistry:getStructureType('barracks'),
		amount = 1,
	}),
--]]
local TASK = {}

--- @param data BehaviorTreeData
function TASK:start(data)
    local unitTypeId = self.taskInfo.unitTypeId
    local structureType = self.taskInfo.structureType
    local amount = self.taskInfo.amount

    if (type(unitTypeId) == 'function') then
        unitTypeId = unitTypeId()
    end

    if (type(structureType) == 'function') then
        structureType = structureType()
    end

    if (type(amount) == 'function') then
        amount = amount()
    end

    if (not unitTypeId or not structureType or not amount) then
        assert(false, 'Invalid unit type id, structure type, or amount')
    end

    self.taskInfo.unitTypeId = unitTypeId
    self.taskInfo.structureType = structureType
    self.taskInfo.amount = amount
end

--- @param data BehaviorTreeData
function TASK:run(data)
	local player = data.player
    local faction = player:getFaction()

    -- Fail immediately if we don't have the housing to support the new units
    local units = faction:getUnits()
    local housing = faction:getResourceInventory():getValue('housing')

	if (#units + self.taskInfo.amount > housing) then
		-- TODO: Add house to the front of the build queue
		print('Not enough housing to support new units')
		self:fail()
		return
	end

    local structures = faction:getStructuresOfType(self.taskInfo.structureType)
    local unitTypeId = self.taskInfo.unitTypeId

	if (not unitTypeId) then
		assert(false, 'Invalid unit type id')
	end

	if (#structures == 0) then
		print('No structures of type', self.taskInfo.structureType)
		self:fail()
		return
	end

    local structure = structures[1]
	local unitGenerationInfo

    for _, info in ipairs(structure:getStructureType().unitGenerationInfo) do
        if (info.unitTypeId == unitTypeId) then
			unitGenerationInfo = info
            break
        end
    end

	assert(unitGenerationInfo, 'Invalid unit generation info')

	local unit = structure:canGenerateUnit(unitGenerationInfo)

	if (unit) then
        print('enqueueUnitGeneration of id', unitTypeId)
		structure:enqueueUnitGeneration(unitGenerationInfo)
		self:success()
		return
	end

    self:fail()
end

return TASK
