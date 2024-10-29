local Interactable = require('libraries.Interactable')

--- Represents a resource value in the game
--- @class Resource : Interactable
--- @field resourceType ResourceTypeRegistry.ResourceRegistration
--- @field supply number
--- @field tiles table
local Resource = DeclareClassWithBase('Resource', Interactable)

--- Initializes the resource
--- @param config table
function Resource:initialize(config)
    config = config or {}

	self.isSelectable = false
	self.supply = 100

	table.Merge(self, config)

	self.startSupply = self.supply
end

--- Called when the resource instance spawns
function Resource:onSpawn()
	if (self.resourceType.onSpawn) then
		self.resourceType:onSpawn(self)
	end
end

--- Gets the type of resource
--- @return ResourceTypeRegistry.ResourceRegistration
function Resource:getResourceType()
    return self.resourceType
end

--- Gets the supply of the resource
--- @return number
function Resource:getSupply()
	return self.supply
end

--- Stop the unit from interacting with the resource
--- @param interactor Interactable
function Resource:stopInteract(interactor)
    local inventory = interactor:getResourceInventory()

    if (inventory:getCurrentResources() == 0) then
        -- Find another resource to go to of the same type
        local world = self:getWorld()
		local faction = interactor:getFaction()
        local nearestResourceInstance = world:findNearestResourceInstance(
            self.resourceType,
            interactor.x,
			interactor.y,
			function(resource)
				local resourceFaction = resource:getFaction()

				if (faction and resourceFaction and resourceFaction ~= faction) then
					return false
				end

				return true
			end)

        if (nearestResourceInstance) then
            interactor:commandTo(nearestResourceInstance.x, nearestResourceInstance.y, nearestResourceInstance)
        else
			interactor:stop()
		end
	else
		-- TODO: and go towards the resource camp, for now we will go to the town hall
		local resourceCamp = interactor:getFaction():getTownHall()
        interactor:commandTo(resourceCamp.x, resourceCamp.y, resourceCamp)
	end
end

--- When an interactable is interacted with
--- @param deltaTime number
--- @param interactor Interactable
function Resource:updateInteract(deltaTime, interactor)
    if (not interactor:isOfType(Unit)) then
        print('Cannot interact with resource as it is not a unit.')
        return
    end

	if (interactor:getUnitType().id ~= 'villager') then
		print('Unit cannot harvest this resource.')
		interactor:stop()
		return
	end

    local inventory = interactor:getResourceInventory()
	interactor:setLastResourceInstance(self)

    -- If our inventory is full, we cannot harvest more
    if (inventory:getRemainingResourceSpace() <= 0) then
        self:stopInteract(interactor)
        return
    end

    -- Set the action active and on the current interactable
    interactor:setCurrentAction('action', self)

    if (self.nextHarvestAt and self.nextHarvestAt > love.timer.getTime()) then
        return
    end

    self.nextHarvestAt = love.timer.getTime() + (self.resourceType.harvestTimeInSeconds or GameConfig.resourceHarvestTimeInSeconds())

    local resourceHarvested = math.min(self.supply, 1, inventory:getRemainingResourceSpace())

    inventory:add(self.resourceType, resourceHarvested)
    self.supply = self.supply - resourceHarvested

    -- Check if the resource supply is depleted
	-- TODO: This may happen multiple times, for multiple units. Hence the isRemoved check in removeResource
    if (self.supply <= 0) then
        self:remove()
        self:stopInteract(interactor)
    end

	return
end

--- Removes the resource from the world
function Resource:remove()
    if (self.isRemoved) then
        return
    end

    self.isRemoved = true

	local world = self:getWorld()

    world:removeResourceInstance(self)

    if (self.tiles) then
        for _, tile in pairs(self.tiles) do
            world:removeTile(tile.layerName, tile.x, tile.y)
        end
    end

	world:updateCollisionMap()

    if (self.resourceType.onRemove) then
        self.resourceType:onRemove(self)
    end

    self.events:trigger('resourceRemoved')
end

--- Called after the resource instance is drawn on screen
--- @param x number
--- @param y number
--- @param width number
--- @param height number
--- @param cameraScale number
function Resource:postDrawOnScreen(x, y, width, height, cameraScale)
	if (self.supply == self.startSupply) then
		return
	end

	local progress = self.supply / self.startSupply
	local radius = width * .25

	love.graphics.drawProgressCircle(x + width * .5, y + height * .5, radius, progress)
end

return Resource
