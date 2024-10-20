--- Represents a unit controller, which can be a player or an AI
--- @class UnitController
--- @field owner? Player
local UnitController = DeclareClass('UnitController')

--- Initializes the unit controller
--- @param config table
function UnitController:initialize(config)
	config = config or {}

	table.Merge(self, config)
end

--- Gets the owner of the controller
--- @return Player|nil
function UnitController:getOwner()
	return self.owner
end

return UnitController
