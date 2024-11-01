local DIRECTIVE = {}

--- Called when the directive is added to the directive list.
--- @param player PlayerComputer
function DIRECTIVE:init(player)
    local units = self.directiveInfo.units

    assert(units, 'Invalid units')
end

--- Returns a string representation of the directive
--- @return string
function DIRECTIVE:getInfoString()
	return 'Attack units'
end

--- Called while the AI is working on the directive.
--- @param player PlayerComputer
--- @return boolean # Whether the directive has been completed
function DIRECTIVE:run(player)
    local faction = player:getFaction()
    local unitsToAttack = self.directiveInfo.units
    local warriors = faction:getUnitsOfType('warrior')

    -- Filter out already dead units
    for i = #unitsToAttack, 1, -1 do
        if (unitsToAttack[i].isRemoved) then
            table.remove(unitsToAttack, i)
        end
    end

    -- If we have no units to attack, we're done
    if (#unitsToAttack == 0) then
		self:debugPrint('No units to attack')
        return true
    end

    -- If we have no warriors, we need to create them
    local targetWarriorCount = #unitsToAttack -- Equal amount of units for now

    if (#warriors < targetWarriorCount) then
        -- We don't have warriors, so we need to create them
        player:prependDirective(
            player:createDirective('HaveUnitsOfType', {
                unitTypeId = 'warrior',
                structureType = StructureTypeRegistry:getStructureType('barracks'),
                amount = targetWarriorCount,
            })
        )

        return false
    end

    -- We have warriors, so we'll set them to attack
	self:setWarriorsToAttack(player, warriors, unitsToAttack)

    -- We're not done attacking yet
    return false
end

--- Called while other directives are being worked on, but we're in the directive list.
--- @param player PlayerComputer
--- @return boolean # Whether the directive has been completed
function DIRECTIVE:queuedUpdate(player)
    -- If we're under attack and gathering resources, we still want to ensure our warriors are attacking
    local faction = player:getFaction()
    local unitsToAttack = self.directiveInfo.units
    local warriors = faction:getUnitsOfType('warrior')

    -- Filter out already dead units
    for i = #unitsToAttack, 1, -1 do
        if (unitsToAttack[i].isRemoved) then
            table.remove(unitsToAttack, i)
        end
    end

    -- If we have no units to attack, we're done
    if (#unitsToAttack == 0) then
		return false
    end

    -- If we have no warriors, we'll wait
    if (#warriors == 0) then
		return false
    end

    -- Check that our warriors are attacking something
    self:setWarriorsToAttack(player, warriors, unitsToAttack)

	return false
end

--- Sets the warriors to attack the specified units
--- @param player PlayerComputer
--- @param warriors table
--- @param unitsToAttack table
function DIRECTIVE:setWarriorsToAttack(player, warriors, unitsToAttack)
	for _, warrior in ipairs(warriors) do
        local isAttacking, victim = warrior:attacking()

		if (not isAttacking or not victim) then
			local unitToTarget = unitsToAttack[1] -- TODO: Find the closest unit to attack
			local warriorInteractable = warrior:getCurrentActionInteractable()

            -- If we're headed to the target, we're good, otherwise we go to attack
			if (not warriorInteractable and warriorInteractable ~= unitToTarget) then
				warrior.isAutoAttacking = false -- do not automatically continue attacking other units
            	warrior:commandTo(unitToTarget.x, unitToTarget.y, unitToTarget)
				self:debugPrint('Warrior ', _, ' is not attacking, setting to attack', unitToTarget, unitToTarget.x, unitToTarget.y)
			end
		end
	end
end

return DIRECTIVE
