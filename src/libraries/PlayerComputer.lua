
--[[
	Let's think about the AI for a moment:
	- We want to create a simple AI that will gather wood until it has 15 wood,
	- then create a farm,
	- then assign idle villagers to gather food,
	- then create a new villager if it has 15 food.

	However we want the behaviour tree here to be generic enough that it can decide for a strategy based on the current state of the game.
	For example later it will want to react to enemy units, or build a barracks if it has enough resources, etc.

	Let's consider our outer tree to be a priority tree, where we will have the following tasks:
	- Check if we're being attacked, if so:
		- If we have soldiers, attack the enemy
		- If we don't have soldiers:
			- If we have barracks, create soldiers
			- If we don't have barracks, create a barracks if we have enough resources
			- If we don't have enough resources just forget about this line of the tree
	- If we're not being attacked:
		- Check if we have have enough resources to create our next structure, if so:
			- Create the structure
		- If we don't have enough resources:
			- Ensure we're gathering resources
			- If we're not gathering resources, find an idle villager and send them to gather resources

	We will have a blackboard where we can store information about the AI's state, such as the order of structures to build, etc.
--]]
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
        -- The order of structures to build
        structuresToBuild = {
            'farmland',
            'house',
			'barracks',
		},
	}

    self.goalTree = self:createGoalTree()

	--- @alias BehaviorTreeData {blackboard: table, player: PlayerComputer}
    self.goalTree:setObject({
        player = self,
		blackboard = self.blackboard,
	})
end

function PlayerComputer:createTask(taskModuleName, taskInfo)
	-- We copy so the task info can differ between tasks of the same type
	local taskDesign = table.Copy(require('ai.tasks.' .. taskModuleName))
    local task = BehaviorTree.Task:new(taskDesign)
    task.taskInfo = taskInfo or {}

	return task
end

function PlayerComputer:createGoalTree()
	return BehaviorTree:new({
		tree = BehaviorTree.Priority:new({
			nodes = {
				-- Check if we're being attacked
				BehaviorTree.Sequence:new({
					nodes = {
						self:createTask('CheckIfAttacked'),
						BehaviorTree.Sequence:new({
							nodes = {
								-- If we have soldiers, attack the enemy
								self:createTask('AttackEnemy'),
								-- If we don't have soldiers
								BehaviorTree.Priority:new({
									nodes = {
										-- If we have barracks, create soldiers
										self:createTask('CreateUnits', {
                                            unitTypeId = 'soldier',
											structureType = StructureTypeRegistry:getStructureType('barracks'),
											amount = 1,
										}),
										-- If we don't have barracks, create a barracks if we have enough resources
										self:createTask('BuildStructures', {
											structureType = StructureTypeRegistry:getStructureType('barracks'),
											amount = 1,
										}),
									},
								}),
							},
						}),
					},
                }),

                -- If we're not being attacked try to build the structure, or otherwise go gather resources
				BehaviorTree.Priority:new({
                    nodes = {
                        -- TODO: The AI is currently hyper focused on creating units. It uses all its villagers for that. That is not good.
						-- TODO: Somehow have the AI split its villagers between gathering other resources too.
						-- Prioritize getting new villagers if we have the housing for them
                        BehaviorTree.Priority:new({
                            nodes = {
								self:createTask('CreateUnits', {
									unitTypeId = 'villager',
									structureType = StructureTypeRegistry:getStructureType('town_hall'),
									amount = 1,
								}),

								-- If we don't have enough resources for a unit, ensure we're gathering resources
								self:createTask('EnsureGatheringResources', {
									desiredResources = StructureTypeRegistry:getStructureType('town_hall'):getUnitGenerationInfo('villager').costs
								}),
							},
						}),

						-- Check if we have have enough resources to create our next structure
						self:createTask('BuildStructures', {
							structureType = function()
								return self:getCurrentStructureToBuild()
							end,
                        }),

						-- If we don't have enough resources
						self:createTask('EnsureGatheringResources', {
							resourceGoal = function()
								return self:getCurrentStructureToBuild()
							end,
						}),
					},
                }),
			},
		}),
	})
end

function PlayerComputer:update(deltaTime)
    self.goalTree:run()
end

function PlayerComputer:findIdleOrRandomUnit(unitTypeId)
    local faction = self:getFaction()
	local units = faction:getUnitsOfType(unitTypeId)

    for _, unit in ipairs(units) do
        if (not unit:isInteracting()) then
            return unit
        end
    end

    return units[math.random(1, #units)]
end

--- Goes through all the structures to build and the faction's structures and returns the next structure to build
function PlayerComputer:getCurrentStructureToBuild()
    local faction = self:getFaction()
	local structuresBuilt = faction:getStructures()
    local structuresToBuild = self.blackboard.structuresToBuild

    for _, structureId in ipairs(structuresToBuild) do
        local structureType = StructureTypeRegistry:getStructureType(structureId)
        local structure = structuresBuilt[structureType.id]

        if (not structure) then
            return structureType
        end
    end

	return nil
end

return PlayerComputer
