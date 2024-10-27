local TASK = {}

--- @param data BehaviorTreeData
function TASK:start(data)

end

--- @param data BehaviorTreeData
function TASK:run(data)
	local faction = data.player:getFaction()

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
