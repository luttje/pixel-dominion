local Player = require('libraries.Player')

--- @class PlayerComputer : Player
---
local PlayerComputer = DeclareClassWithBase('PlayerComputer', Player)

function PlayerComputer:initialize(config)
    config = config or {}

    table.Merge(self, config)
end

--- Called for the computer player to think
--- @param deltaTime number
function PlayerComputer:update(deltaTime)
    if (self.thought) then
        return
    end

    local faction = self:getFaction()
	local world = self:getWorld()
    local villager = faction:getUnits()[1]
	local resourceType = ResourceTypeRegistry:getResourceType('wood')
	local resource = world:findNearestResourceInstance(resourceType, villager.x, villager.y)

    print('Computer found resource', resource)

	if (resource) then
		villager:commandTo(resource.x, resource.y, resource)
	end

	self.thought = true
end

return PlayerComputer
