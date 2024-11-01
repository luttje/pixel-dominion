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
        --- The directives the AI is working on
		--- @type Directive[]
        directives = {},
	}
end

--- Generates new directives for the AI to work on
function PlayerComputer:generateNewDirectives()
	local faction = self:getFaction()
    local currentVillagers = #faction:getUnitsOfType('villager')
    local currentWarriors = #faction:getUnitsOfType('warrior')

    -- The AI should handle this directive to reach a certain population by:
    -- - Checking if we can create a new villager, if we can, create it
    -- - If we can't create a new villager, because we have enough food, but not enough housing, build a house
    -- - If we can't build a house, because we don't have enough resources, ensure we're gathering resources (wood)
    -- - If we can't create a villager, because we don't have enough food, ensure we're gathering food
    -- - If we have no food to gather, create a farm
	-- - If we have no wood for a farm, ensure we're gathering wood
	-- Those sub-directives are prepended to the directive list, so they are handled first
    self:appendDirective(
		self:createDirective('HaveUnitsOfType', {
			unitTypeId = 'villager',
			structureType = StructureTypeRegistry:getStructureType('town_hall'),
			amount = currentVillagers + 5,
		})
    )

    -- Create a warrior (the AI will think of what it needs to to do to get there)
	-- Like building barracks first (since those generate warriors)
	self:appendDirective(
		self:createDirective('HaveUnitsOfType', {
			unitTypeId = 'warrior',
			structureType = StructureTypeRegistry:getStructureType('barracks'),
			amount = currentWarriors + 1,
		})
	)

    -- Always stockpile these resources
    local factionInventory = faction:getResourceInventory()

	self:appendDirective(
		self:createDirective('HaveGatheredResources', {
			resourceTypeId = 'food',
			desiredAmount = 150 + factionInventory:getValue('food'),
		})
	)
	self:appendDirective(
		self:createDirective('HaveGatheredResources', {
			resourceTypeId = 'wood',
			desiredAmount = 100 + factionInventory:getValue('wood'),
		})
	)
	self:appendDirective(
		self:createDirective('HaveGatheredResources', {
			resourceTypeId = 'stone',
			desiredAmount = 100 + factionInventory:getValue('stone'),
		})
	)
	self:appendDirective(
		self:createDirective('HaveGatheredResources', {
			resourceTypeId = 'gold',
			desiredAmount = 50 + factionInventory:getValue('gold'),
		})
	)

end

--- Generates important new directives for the AI to work on, like when the AI is under attack
function PlayerComputer:generateImportantNewDirectives()
	-- Check if we're under attack
	local attackingUnits = self.faction:getAttackingUnits()

	if (#attackingUnits == 0) then
		return
	end

	if (self:hasDirective('AttackUnits')) then
		return
	end

	-- Force warriors to attack the enemy (which will automatically add directives to create warriors if we don't have them)
	-- TODO: Split our warriors into multiple groups, so we can defend from multiple locations
	self:prependDirective(
		self:createDirective('AttackUnits', {
			units = attackingUnits,
		})
	)
end

--- Optimizes the directives where possible, by combining them where possible
--- For example multiple sequential HaveGatheredResources directives will be merged into HaveGatheredMultipleResources
function PlayerComputer:optimizeDirectives()
    local newDirectives = {}
    local currentGatherDirectives = {}

	local function createMergedDirective(currentGatherDirectives)
		local resourceRequirements = {}

		for _, gatherDirective in ipairs(currentGatherDirectives) do
			table.insert(resourceRequirements, {
				resourceTypeId = gatherDirective.directiveInfo.resourceTypeId,
				desiredAmount = gatherDirective.directiveInfo.desiredAmount,
			})
		end

		local newDirective = self:createDirective('HaveGatheredMultipleResources', {
            requirements = resourceRequirements,
		})
		newDirective:init(self)
        table.insert(newDirectives, newDirective)
	end

    -- Collect directives and identify optimization opportunities
    for _, directive in ipairs(self.blackboard.directives) do
        if (directive.id == 'HaveGatheredResources') then
            table.insert(currentGatherDirectives, directive)
        else
            -- Process any accumulated gather directives before adding the non-gather directive
            if #currentGatherDirectives > 1 then
				createMergedDirective(currentGatherDirectives)
            elseif (#currentGatherDirectives == 1) then
                -- Just add the single gather directive as is
                table.insert(newDirectives, currentGatherDirectives[1])
            end

            -- Add the non-gather directive
			table.insert(newDirectives, directive)

            -- Reset gather directives collection
            currentGatherDirectives = {}
        end
    end

    -- Handle any remaining gather directives at the end
    if (#currentGatherDirectives > 1) then
		createMergedDirective(currentGatherDirectives)
    elseif #currentGatherDirectives == 1 then
        table.insert(newDirectives, currentGatherDirectives[1])
    end

    -- Replace the old directives with the optimized ones
	self.blackboard.directives = newDirectives
end

--- Adds a directive to the AI blackboard at the specified index
--- @param directive Directive
--- @param index number
function PlayerComputer:addDirectiveAt(directive, index)
	table.insert(self.blackboard.directives, index, directive)

    -- Initialize any directive-specific data
    if (directive.init) then
        directive:init(self)
    end
end

--- Appends a directive to the end of the AI blackboard directive list
--- @param directive Directive
function PlayerComputer:appendDirective(directive)
	self:addDirectiveAt(directive, #self.blackboard.directives + 1)
end

--- Prepends a directive to the front of the AI blackboard directive list
--- @param directive Directive
function PlayerComputer:prependDirective(directive)
    self:addDirectiveAt(directive, 1)
end

--- Checks if there is a directive with the specified id in the AI blackboard directive list
--- @param directiveId string
--- @param directiveInfo? table
--- @return boolean
function PlayerComputer:hasDirective(directiveId, directiveInfo)
	for _, directive in ipairs(self.blackboard.directives) do
		if (directive.id == directiveId) then
			if (directiveInfo) then
				-- Check if the directive info is the same
				local isSame = true

				for key, value in pairs(directiveInfo) do
					if (directive.directiveInfo[key] ~= value) then
						isSame = false
						break
					end
				end

				if (isSame) then
					return true
				end
			end

			return true
		end
	end

	return false
end

--- Counts the amount of directives with the specified id in the AI blackboard directive list
--- @param directiveId string
--- @param directiveInfo? table
--- @return number
function PlayerComputer:countDirectives(directiveId, directiveInfo)
	local count = 0

	for _, directive in ipairs(self.blackboard.directives) do
		if (directive.id == directiveId) then
			if (directiveInfo) then
				-- Check if the directive info is the same
				local isSame = true

				for key, value in pairs(directiveInfo) do
					if (directive.directiveInfo[key] ~= value) then
						isSame = false
						break
					end
				end

				if (isSame) then
					count = count + 1
				end
			else
				count = count + 1
			end
		end
	end

	return count
end

--- Removes the first directive from the AI blackboard directive list
--- @return Directive
function PlayerComputer:removeFirstDirective()
    local directive = table.remove(self.blackboard.directives, 1)

    return directive
end

--- Gets the current directive the AI is working on
--- @return Directive
function PlayerComputer:getCurrentDirective()
    return self.blackboard.directives[1]
end

--- Gets the directive list
--- @return Directive[]
function PlayerComputer:getDirectiveList()
	return self.blackboard.directives
end

--- Prints the current directive list
function PlayerComputer:debugDirectiveList()
	print('-----------------------------------')
    if (#self.blackboard.directives > 0) then
        print('Directives for player: ', self:getName())

		for i, directive in ipairs(self.blackboard.directives) do
			print(i, directive.id, directive:getInfoString())
		end
	else
		print('No directives for player: ', self:getName())
	end
	print('\n')
end

--- Creates a directive for the AI
--- @param directiveModuleName string
--- @param directiveInfo? table
--- @return Directive
function PlayerComputer:createDirective(directiveModuleName, directiveInfo)
	-- We copy so the directive info can differ between directives of the same type
	local directiveDesign = table.Copy(require('directives.' .. directiveModuleName))

    --- @class Directive
    --- @field blackboard table
    --- @field player PlayerComputer
    --- @field directiveInfo table
    --- @field init fun(self: Directive, player: PlayerComputer)
    --- @field run fun(self: Directive, player: PlayerComputer): boolean
	--- @field queuedUpdate? fun(self: Directive, player: PlayerComputer): boolean
    --- @field getInfoString fun(self: Directive): string
    local directive = directiveDesign

	directive.id = directiveModuleName
	directive.directiveInfo = directiveInfo or {}
	directive.blackboard = self.blackboard
	directive.player = self
    directive.getInfoString = directive.getInfoString or function(directive)
        return ''
    end

	directive.debugPrint = function(directiveNode, ...)
		print('[AI Directive] ', self:getName(), ' | ', ...)
	end

	return directive
end

--- Will call the run function of the current directive the AI is working on
--- If the directives change while we are working on the current directive, we will work on the new current directive
--- the next update
function PlayerComputer:update(deltaTime)
    if (self:getFaction().isDefeated) then
        -- Don't think if we don't have a faction (since we died/surrendered)
        return
    end

    local currentDirective = self:getCurrentDirective()

    if (not currentDirective) then
        self:generateNewDirectives()
        return
    end

    local isDirectiveCompleted = currentDirective:run(self)

    if (isDirectiveCompleted) then
        self:removeFirstDirective()
        self.faction:onBehaviorDirectiveCompleted(currentDirective)
    end

    -- Run the queuedUpdate function for all directives so they can still do logic
    local directivesToRemove = {}
    for i, directive in ipairs(self.blackboard.directives) do
        if (directive.queuedUpdate) then
            if (directive:queuedUpdate(self) == true) then
                table.insert(directivesToRemove, i)
            end
        end
    end

    for i = #directivesToRemove, 1, -1 do
        table.remove(self.blackboard.directives, directivesToRemove[i])
    end

    self:generateImportantNewDirectives()
    self:optimizeDirectives()

    local faction = self:getFaction()

	if (faction:shouldSurrender()) then
		faction:surrender()
	end
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

function PlayerComputer:findIdleOrRandomUnits(unitTypeId, minimumAmount)
	local faction = self:getFaction()
	local units = faction:getUnitsOfType(unitTypeId)
	minimumAmount = math.min(minimumAmount or 1, #units)

	local selectedUnits = self:findIdleUnits(unitTypeId)

	while (#selectedUnits < minimumAmount) do
		local randomUnit = self:findRandomUnit(unitTypeId)

		if (not table.HasValue(selectedUnits, randomUnit)) then
			table.insert(selectedUnits, randomUnit)
		end
	end

	return selectedUnits
end

return PlayerComputer
