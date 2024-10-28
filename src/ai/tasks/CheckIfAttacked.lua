--- @type BehaviorTreeTask
local TASK = {}

--- @param player PlayerComputer
function TASK:start(player)

end

--- @param player PlayerComputer
function TASK:run(player)
	local faction = player:getFaction()

    -- Check if any of the faction's structures/units are being attacked
	for i, structure in ipairs(faction:getInteractables()) do
        if (structure:recentlyDamaged()) then
            -- By not calling fail, the following tasks will be executed
			self:success()
			return
		end
	end

	self:fail()
end

return TASK
