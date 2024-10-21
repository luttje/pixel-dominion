require('libraries.Interactable')

--- Represents a structure value in the game
--- @class Structure : Interactable
--- @field structureType StructureTypeRegistry.StructureRegistration
--- @field faction Faction
--- @field supply number
--- @field tiles table
local Structure = DeclareClassWithBase('Structure', Interactable)

--- Initializes the structure
--- @param config table
function Structure:initialize(config)
    config = config or {}

	table.Merge(self, config)
end

--- Gets the type of structure
--- @return StructureTypeRegistry.StructureRegistration
function Structure:getStructureType()
    return self.structureType
end

--- Gets the faction
--- @return Faction
function Structure:getFaction()
	return self.faction
end

--- Called every tick
--- @param deltaTime number
function Structure:update(deltaTime)
	if (not self.nextUpdateTime) then
		self.nextUpdateTime = GameConfig.structureUpdateTimeInSeconds
	end

	self.nextUpdateTime = self.nextUpdateTime - deltaTime

	if (self.nextUpdateTime <= 0) then
		self.nextUpdateTime = GameConfig.structureUpdateTimeInSeconds

		self:getStructureType():onTimedUpdate(self)
	end
end

--- When an interactable is interacted with
--- @param deltaTime number
--- @param interactable Interactable
function Structure:updateInteract(deltaTime, interactable)
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

return Structure
