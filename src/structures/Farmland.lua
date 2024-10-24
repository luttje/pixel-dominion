local STRUCTURE = {}

STRUCTURE.id = 'farmland'
STRUCTURE.name = 'Farmland'

STRUCTURE.imagePath = 'assets/images/structures/farmland.png'
STRUCTURE.requiredResources = {
	wood = 15,
}

STRUCTURE.structureTilesetInfo = {
	-- Farmland 1
    {
		-- Top
		{
			tilesetId = 2,
			tileId = 816,
			targetLayer = 'Dynamic_Bottom_NoCollide',
			offsetX = 0,
			offsetY = -1,
		},
		{
			tilesetId = 2,
			tileId = 817,
			targetLayer = 'Dynamic_Bottom_NoCollide',
			offsetX = 1,
			offsetY = -1,
        },
		-- Bottom
		{
			tilesetId = 2,
			tileId = 916,
			targetLayer = 'Dynamic_Bottom_NoCollide',
			offsetX = 0,
			offsetY = 0,
		},
		{
			tilesetId = 2,
			tileId = 917,
			targetLayer = 'Dynamic_Bottom_NoCollide',
			offsetX = 1,
			offsetY = 0,
        },
    },
}

--- Called when the structure is created in the world
--- @param structure Structure
--- @param builders Unit[]
function STRUCTURE:onSpawn(structure, builders)
    local world = CurrentWorld

	local foodResource = ResourceTypeRegistry:getResourceType('food')

    -- Spawn a hidden farmable resource at this structure's location
    local x, y = structure:getWorldPosition()

	local resource = Resource({
		resourceType = foodResource,
		x = x,
        y = y,
    })

	-- If the resource depletes, remove the structure
	resource.events:on('resourceRemoved', function()
		structure.removingBecauseResourceDepleted = true
		structure:removeStructure()
	end)

    world:addResourceInstance(resource)
	structure.resource = resource

    -- Have the builders start harvesting the resource
	for _, builder in ipairs(builders) do
		builder:commandTo(x, y, resource)
	end
end

--- Called when the structure is destroyed/removed from the world
--- @param structure Structure
function STRUCTURE:onRemove(structure)
    if (structure.removingBecauseResourceDepleted) then
        return
    end

	-- If we remove the structure before the resource is depleted, remove the resource
	structure.resource:removeResource()
end

--- Returns whether the structure can be built by the faction. Resources are checked
--- before this function is called.
--- @param faction Faction
--- @return boolean
function STRUCTURE:canBeBuiltByFaction(faction)
	return true
end

--- When an structure is interacted with by a unit.
--- @param structure Structure
--- @param deltaTime number
--- @param interactor Interactable
function STRUCTURE:updateInteract(structure, deltaTime, interactor)
    -- Have the interactor start harvesting the resource which is at this structure's location
	interactor:commandTo(structure.resource.x, structure.resource.y, structure.resource)
end

return STRUCTURE