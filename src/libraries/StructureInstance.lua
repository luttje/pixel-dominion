require('libraries.Interactable')

--- Represents a structure value in the game
--- @class StructureInstance : Interactable
--- @field structureType StructureTypeRegistry.StructureRegistration
--- @field supply number
--- @field tiles table
local StructureInstance = DeclareClassWithBase('StructureInstance', Interactable)

--- Initializes the structure
--- @param config table
function StructureInstance:initialize(config)
    config = config or {}

	table.Merge(self, config)
end

--- Gets the type of structure
--- @return StructureTypeRegistry.StructureRegistration
function StructureInstance:getStructureType()
    return self.structureType
end

--- When an interactable is interacted with
--- @param deltaTime number
--- @param interactable Interactable
function StructureInstance:updateInteract(deltaTime, interactable)
    if (not interactable:isOfType(Unit)) then
        print('Cannot interact with structure as it is not a unit.')
        return
    end

	local inventory = interactable:getStructureInventory()

    -- -- If our inventory is full, we cannot harvest more
    -- if (inventory:getRemainingStructureSpace() <= 0) then
    --     -- Stop the action
	-- 	-- TODO: and go towards the structure camp
	-- 	interactable:setCurrentAction('idle', nil)

	-- 	return
	-- end
end

return StructureInstance
