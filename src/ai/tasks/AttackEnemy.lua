local TASK = {}

--- @param data BehaviorTreeData
function TASK:start(data)

end

--- @param data BehaviorTreeData
function TASK:run(data)
	local faction = data.player:getFaction()

    -- Find the interactables being attacked
	local attackers = {}

	for i, structure in ipairs(faction:getInteractables()) do
		local recentlyDamaged, damagedBy = structure:recentlyDamaged()

        if (recentlyDamaged) then
			table.insert(attackers, damagedBy)
		end
	end

    -- If there are interactables being attacked, check if we have enough soldiers to attack the enemy
	if (#attackers > 0) then
		local soldiers = faction:getUnitsOfType('soldier')

        if (#soldiers > 0) then
            -- Send the soldiers to attack the enemy
			for i, soldier in ipairs(soldiers) do
				local attacker = attackers[math.min(i, #attackers)]

				soldier:commandTo(attacker.x, attacker.y, attacker)
			end

			self:success()
			return
		end
	end
end

return TASK
