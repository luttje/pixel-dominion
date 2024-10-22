require('libraries.Interactable')

--- Represents a resource value in the game
--- @class ResourceInstance : Interactable
--- @field resourceType ResourceTypeRegistry.ResourceRegistration
--- @field supply number
--- @field tiles table
local ResourceInstance = DeclareClassWithBase('ResourceInstance', Interactable)

--- Initializes the resource
--- @param config table
function ResourceInstance:initialize(config)
    config = config or {}

	self.isSelectable = false
	self.supply = 100
	self.harvestTimer = 0

	table.Merge(self, config)
end

--- Gets the type of resource
--- @return ResourceTypeRegistry.ResourceRegistration
function ResourceInstance:getResourceType()
    return self.resourceType
end

--- When an interactable is interacted with
--- @param deltaTime number
--- @param interactable Interactable
function ResourceInstance:updateInteract(deltaTime, interactable)
    if (not interactable:isOfType(Unit)) then
        print('Cannot interact with resource as it is not a unit.')
        return
    end

	local inventory = interactable:getResourceInventory()

    -- If our inventory is full, we cannot harvest more
    if (inventory:getRemainingResourceSpace() <= 0) then
        -- Stop the action
		-- TODO: and go towards the resource camp, for now we will go to the town hall
		local resourceCamp = CurrentPlayer:getFaction():getTownHall()
		interactable:commandTo(resourceCamp.x, resourceCamp.y, resourceCamp)

		return
	end

    -- Set the action active and on the current interactable
	interactable:setCurrentAction('action', self)

    assert(CurrentWorld, 'World is required.')

	self.harvestTimer = self.harvestTimer + deltaTime

    if (self.harvestTimer < GameConfig.resourceHarvestTimeInSeconds) then
        return
    end

	self.harvestTimer = 0

    local resourceHarvested = math.min(self.supply, 1, inventory:getRemainingResourceSpace())

	inventory:add(self.resourceType, resourceHarvested)
	self.supply = self.supply - resourceHarvested

	-- Check if the resource supply is depleted
	if (self.supply <= 0) then
		-- Remove all tiles from the world when supply runs out
        for _, tile in pairs(self.tiles) do
            CurrentWorld:removeTile(tile.layerName, tile.x, tile.y)
        end

        CurrentWorld:removeResourceInstance(self)
		CurrentWorld:updateCollisionMap()
	end
end

return ResourceInstance
