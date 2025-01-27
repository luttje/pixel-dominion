--- @class StructureTypeRegistry
local StructureTypeRegistry = DeclareClass('StructureTypeRegistry')

--- @alias UnitGenerationInfo {id: string, text: string, icon: string, unitTypeId: string, generationTimeInSeconds: number, costs: table<string, number>}

--[[
	StructureRegistration
--]]

--- @class StructureTypeRegistry.StructureRegistration
---
--- @field id string The unique id of the structure.
--- @field name string The name of the structure.
---
--- @field sightRange? number The sight range of the structure.
--- @field unitGenerationInfo table[]|nil The unit types that this structure generates.
--- @field dropOffForResources? table<string, boolean> A table of resource types that this structure can accept as a drop-off point.
--- @field requiredResources table<string, number> The resources required to build the structure.
---
--- @field structureTilesetInfo table<number, table> The tileset information used to render the structure in the world.
--- @field imagePath string The path to the image used to render the structure.
---
--- @field updateInteract? fun(structureType: StructureTypeRegistry.StructureRegistration, structure: Structure, deltaTime: number, interactor: Interactable): boolean A function that is called when the structure is interacted with.
---
StructureTypeRegistry.StructureRegistration = DeclareClass('StructureTypeRegistry.StructureRegistration')

function StructureTypeRegistry.StructureRegistration:initialize(config)
	assert(config.id, 'Structure id is required.')

	config = config or {}

	table.Merge(self, config)

	self.image = ImageCache:get(self.imagePath)
    self.imageWidth, self.imageHeight = self.image:getDimensions()
end

--- Spawns this resource at the given tile position
--- @param world World The world to spawn the resource in
--- @param faction Faction The faction that owns the resource
--- @param x number
--- @param y number
--- @param builders? Unit[]
--- @return Structure
function StructureTypeRegistry.StructureRegistration:spawnAtTile(world, faction, x, y, builders)
	assert(self.structureTilesetInfo, 'Resource structureTilesetInfo is required.')

	local tiles = {}
	local structureVariant = table.Random(self.structureTilesetInfo)

	for _, tileInfo in ipairs(structureVariant) do
		local worldX = x + (tileInfo.offsetX or 0)
		local worldY = y + (tileInfo.offsetY or 0)

		-- Track the tiles that belong to this resource so they can be removed later
		tiles[#tiles + 1] = {
			layerName = tileInfo.targetLayer,
			tilesetId = tileInfo.tilesetId,
			tileId = tileInfo.tileId,
			x = worldX,
			y = worldY,
			offsetX = tileInfo.offsetX or 0,
			offsetY = tileInfo.offsetY or 0
		}
	end

	local structure = Structure({
		structureType = self,
		faction = faction,
		x = x,
		y = y,
		tiles = tiles,
        world = world,
		sightRange = self.sightRange,
	})

    structure:onSpawn(builders)

	return structure
end

--- Draws the interactable on the hud
--- @param structure Structure|nil
--- @param x number
--- @param y number
--- @param width number
--- @param height number
function StructureTypeRegistry.StructureRegistration:drawHudIcon(structure, x, y, width, height)
	local scaleX = width / self.imageWidth
	local scaleY = height / self.imageHeight

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(self.image, x, y, 0, scaleX, scaleY)
end

--- Draw the ghost of the structure on the screen
--- @param screenX number
--- @param screenY number
--- @param screenCameraScale number
--- @param canPlace boolean
function StructureTypeRegistry.StructureRegistration:drawGhost(screenX, screenY, screenCameraScale, canPlace)
    local scaleX = screenCameraScale
    local scaleY = screenCameraScale

    if (not canPlace) then
        love.graphics.setColor(1, 0, 0, .5)
    else
        love.graphics.setColor(1, 1, 1, .5)
    end

    -- TODO: Hard-coded bottom left tile offset for all our structures. This should be calculated somehow
	screenY = screenY - (GameConfig.tileSize * scaleY)

    love.graphics.draw(self.image, screenX, screenY, 0, scaleX, scaleY)
end

--- Determines whether the structure can be placed at the given tile position
--- @param world World
--- @param worldX number
--- @param worldY number
--- @return boolean
function StructureTypeRegistry.StructureRegistration:canPlaceAt(world, worldX, worldY)
    -- Use the world to check if the structure can be placed at the given tile position
    for _, tileInfo in ipairs(self.structureTilesetInfo[1]) do
        local tileX = worldX + (tileInfo.offsetX or 0)
        local tileY = worldY + (tileInfo.offsetY or 0)

        if (world:isTileOccupied(tileX, tileY, true)) then
            return false
        end
    end

	return true
end

--- Checks whether the given faction can build this structure, first checking if the faction has the required resources
--- @param faction Faction
function StructureTypeRegistry.StructureRegistration:canBeBuilt(faction)
    if (self.requiredResources) then
        for resourceType, amount in pairs(self.requiredResources) do
            if (not faction:getResourceInventory():has(resourceType, amount)) then
                return false
            end
        end
    end

    if (self.canBeBuiltByFaction) then
        return self.canBeBuiltByFaction(faction)
    end

    return true
end

--- Subtracts the required resources from the faction's inventory
--- @param faction Faction
function StructureTypeRegistry.StructureRegistration:subtractResources(faction)
	if (self.requiredResources) then
		for resourceType, amount in pairs(self.requiredResources) do
			faction:getResourceInventory():remove(resourceType, amount)
		end
	end
end

--- Gets the unit generation info for a unit type id
--- @param unitTypeId string
--- @return UnitGenerationInfo|nil
function StructureTypeRegistry.StructureRegistration:getUnitGenerationInfo(unitTypeId)
	if (self.unitGenerationInfo) then
		for _, unitInfo in ipairs(self.unitGenerationInfo) do
			if (unitInfo.unitTypeId == unitTypeId) then
				return unitInfo
			end
		end
	end

	return nil
end

--[[
	Registry methods
--]]

local registeredStructureTypes = {}

function StructureTypeRegistry:registerStructureType(structureId, config)
	config = config or {}
	config.id = structureId

	registeredStructureTypes[structureId] = StructureTypeRegistry.StructureRegistration(config)

	return registeredStructureTypes[structureId]
end

function StructureTypeRegistry:removeStructureType(structureId)
	registeredStructureTypes[structureId] = nil
end

function StructureTypeRegistry:getStructureType(structureId)
	return registeredStructureTypes[structureId]
end

function StructureTypeRegistry:getAllStructureTypes()
	local structureConfigs = {}

	for _, config in pairs(registeredStructureTypes) do
		table.insert(structureConfigs, config)
	end

	return structureConfigs
end

return StructureTypeRegistry
