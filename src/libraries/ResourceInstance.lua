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

	self.startSupply = self.supply
end

--- Called when the resource instance spawns
function ResourceInstance:onSpawn()
	if (self.resourceType.onSpawn) then
		self.resourceType:onSpawn(self)
	end
end

--- Gets the type of resource
--- @return ResourceTypeRegistry.ResourceRegistration
function ResourceInstance:getResourceType()
	return self.resourceType
end

--- Stop the unit from interacting with the resource
--- @param interactor Interactable
function ResourceInstance:stopInteract(interactor)
    local inventory = interactor:getResourceInventory()

    if (inventory:getCurrentResources() == 0) then
        -- Find another resource to go to of the same type
        local nearestResourceInstance = CurrentWorld:findNearestResourceInstance(
            self.resourceType, interactor.x, interactor.y)

        if (nearestResourceInstance) then
            interactor:commandTo(nearestResourceInstance.x, nearestResourceInstance.y, nearestResourceInstance)
        else
            print('No alternative resource found. Stopping')
			interactor:stop()
		end
	else
		-- TODO: and go towards the resource camp, for now we will go to the town hall
		local resourceCamp = CurrentPlayer:getFaction():getTownHall()
		interactor:commandTo(resourceCamp.x, resourceCamp.y, resourceCamp)
	end
end

--- When an interactable is interacted with
--- @param deltaTime number
--- @param interactor Interactable
function ResourceInstance:updateInteract(deltaTime, interactor)
    if (not interactor:isOfType(Unit)) then
        print('Cannot interact with resource as it is not a unit.')
        return
    end

    local inventory = interactor:getResourceInventory()

    -- If our inventory is full, we cannot harvest more
    if (inventory:getRemainingResourceSpace() <= 0) then
        self:stopInteract(interactor)
        return
    end

    -- Set the action active and on the current interactable
    interactor:setCurrentAction('action', self)

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
        self:removeResource()
        self:stopInteract(interactor)
    end
end

--- Removes the resource from the world
function ResourceInstance:removeResource()
	local world = CurrentWorld

	for _, tile in pairs(self.tiles) do
		world:removeTile(tile.layerName, tile.x, tile.y)
	end

	world:removeResourceInstance(self)
	world:updateCollisionMap()

	if (self.resourceType.onRemove) then
		self.resourceType:onRemove(self)
	end
end

--- Called after the resource instance is drawn on screen
--- @param x number
--- @param y number
--- @param width number
--- @param height number
--- @param cameraScale number
function ResourceInstance:postDrawOnScreen(x, y, width, height, cameraScale)
	if (self.supply == self.startSupply) then
		return
	end

	local progress = self.supply / self.startSupply
	local radius = width * .25

	love.graphics.drawProgressCircle(x + width * .5, y + height * .5, radius, progress)
end

return ResourceInstance
