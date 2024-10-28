local Player = require('libraries.Player')

--- @class PlayerComputer : Player
---
local PlayerComputer = DeclareClassWithBase('PlayerComputer', Player)

function PlayerComputer:initialize(config)
    config = config or {}

    table.Merge(self, config)

    --- The blackboard for the AI where it can store information
	--- @type table
    self.blackboard = {
        --- The goals the AI is working on
		--- @type BehaviorGoal[]
        goals = {},
	}
end

--- Generates new goals for the AI to work on
function PlayerComputer:generateNewGoals()
	local faction = self:getFaction()
    local currentVillagers = #faction:getUnitsOfType('villager')
    local currentWarriors = #faction:getUnitsOfType('warrior')

    -- The AI should handle this goal to reach a certain population by:
    -- - Checking if we can create a new villager, if we can, create it
    -- - If we can't create a new villager, because we have enough food, but not enough housing, build a house
    -- - If we can't build a house, because we don't have enough resources, ensure we're gathering resources (wood)
    -- - If we can't create a villager, because we don't have enough food, ensure we're gathering food
    -- - If we have no food to gather, create a farm
	-- - If we have no wood for a farm, ensure we're gathering wood
	-- Those sub-goals are prepended to the goal list, so they are handled first
    self:appendGoal(
		self:createGoal('HaveUnitsOfType', {
			unitTypeId = 'villager',
			structureType = StructureTypeRegistry:getStructureType('town_hall'),
			amount = currentVillagers + 5,
		})
    )

    -- Create a warrior (the AI will think of what it needs to to do to get there)
	-- Like building barracks first (since those generate warriors)
	self:appendGoal(
		self:createGoal('HaveUnitsOfType', {
			unitTypeId = 'warrior',
			structureType = StructureTypeRegistry:getStructureType('barracks'),
			amount = currentWarriors + 1,
		})
	)
end

--- Generates important new goals for the AI to work on, like when the AI is under attack
function PlayerComputer:generateImportantNewGoals()
    -- Check if we're under attack
    local attackingUnits = self.faction:getAttackingUnits()

	if (#attackingUnits == 0) then
		return
	end

	if (self:hasGoal('AttackUnits')) then
		return
	end

    -- Force warriors to attack the enemy (which will automatically add goals to create warriors if we don't have them)
	-- TODO: Split our warriors into multiple groups, so we can defend from multiple locations
	self:prependGoal(
		self:createGoal('AttackUnits', {
			units = attackingUnits,
		})
	)
end

--- Adds a goal to the AI blackboard at the specified index
--- @param goal BehaviorGoal
--- @param index number
function PlayerComputer:addGoalAt(goal, index)
	table.insert(self.blackboard.goals, index, goal)

    -- Initialize any goal-specific data
    if (goal.init) then
        goal:init(self)
    end

	self:debugGoalList()
end

--- Appends a goal to the end of the AI blackboard goal list
--- @param goal BehaviorGoal
function PlayerComputer:appendGoal(goal)
	self:addGoalAt(goal, #self.blackboard.goals + 1)
end

--- Prepends a goal to the front of the AI blackboard goal list
--- @param goal BehaviorGoal
function PlayerComputer:prependGoal(goal)
    self:addGoalAt(goal, 1)
end

--- Checks if there is a goal with the specified id in the AI blackboard goal list
--- @param goalId string
--- @return boolean
function PlayerComputer:hasGoal(goalId)
	for _, goal in ipairs(self.blackboard.goals) do
		if (goal.id == goalId) then
			return true
		end
	end

	return false
end

--- Removes the first goal from the AI blackboard goal list
--- @return BehaviorGoal
function PlayerComputer:removeFirstGoal()
    local goal = table.remove(self.blackboard.goals, 1)

    self:debugGoalList()

	return goal
end

--- Gets the current goal the AI is working on
--- @return BehaviorGoal
function PlayerComputer:getCurrentGoal()
	return self.blackboard.goals[1]
end

--- Prints the current goal list
function PlayerComputer:debugGoalList()
	print('-----------------------------------')
    if (#self.blackboard.goals > 0) then
        print('Goals for player: ', self:getName())

		for i, goal in ipairs(self.blackboard.goals) do
			print(i, goal.id, goal:getInfoString())
		end
	else
		print('No goals for player: ', self:getName())
	end
	print('\n')
end

--- Creates a goal for the AI
--- @param goalModuleName string
--- @param goalInfo? table
--- @return BehaviorGoal
function PlayerComputer:createGoal(goalModuleName, goalInfo)
	-- We copy so the goal info can differ between goals of the same type
	local goalDesign = table.Copy(require('ai.goals.' .. goalModuleName))

    --- @class BehaviorGoal
    --- @field blackboard table
    --- @field player PlayerComputer
    --- @field goalInfo table
    --- @field init fun(self: BehaviorGoal, player: PlayerComputer)
    --- @field run fun(self: BehaviorGoal, player: PlayerComputer): boolean
	--- @field onOtherGoalRun? fun(self: BehaviorGoal, player: PlayerComputer)
    --- @field getInfoString fun(self: BehaviorGoal): string
    local goal = goalDesign

	goal.id = goalModuleName
	goal.goalInfo = goalInfo or {}
	goal.blackboard = self.blackboard
	goal.player = self
    goal.getInfoString = goal.getInfoString or function(goal)
        return ''
    end

	goal.debugPrint = function(goalNode, ...)
		print('[AI Goal] ', self:getName(), ' | ', ...)
	end

	return goal
end

--- Will call the run function of the current goal the AI is working on
--- If the goals change while we are working on the current goal, we will work on the new current goal
--- the next update
function PlayerComputer:update(deltaTime)
    if (not self:getFaction()) then
		-- Don't think if we don't have a faction (since we died)
        return
    end

	local currentGoal = self:getCurrentGoal()

    if (not currentGoal) then
        self:generateNewGoals()
        return
    end

	local isGoalCompleted = currentGoal:run(self)

    if (isGoalCompleted) then
        self:removeFirstGoal()
    end

    -- Run the queuedUpdate function for all goals so they can still do logic, even if they can't finish
	for _, goal in ipairs(self.blackboard.goals) do
		if (goal.queuedUpdate) then
			goal:queuedUpdate(self)
		end
	end

	self:generateImportantNewGoals()
end

function PlayerComputer:findIdleUnits(unitTypeId)
	local faction = self:getFaction()
	local units = faction:getUnitsOfType(unitTypeId)
	local selectedUnits = {}

	for _, unit in ipairs(units) do
		if (not unit:isInteracting()) then
			table.insert(selectedUnits, unit)
		end
	end

	return selectedUnits
end

function PlayerComputer:findRandomUnit(unitTypeId)
	local faction = self:getFaction()
	local units = faction:getUnitsOfType(unitTypeId)

	return units[math.random(1, #units)]
end

function PlayerComputer:findIdleUnitsOrRandomUnit(unitTypeId)
	local selectedUnits = self:findIdleUnits(unitTypeId)

	if (#selectedUnits == 0) then
		selectedUnits = {self:findRandomUnit(unitTypeId)}
	end

	return selectedUnits
end

return PlayerComputer
