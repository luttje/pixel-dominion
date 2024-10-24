local STRUCTURE = {}

STRUCTURE.id = 'barracks'
STRUCTURE.name = 'Barracks'

STRUCTURE.imagePath = 'assets/images/structures/barracks.png'
STRUCTURE.requiredResources = {
	wood = 90,
    stone = 40,
	gold = 10,
}

STRUCTURE.structureTilesetInfo = {
	-- Barracks 1
    {
		-- Top
		{
			tilesetId = 2,
			tileId = 820,
			targetLayer = 'Dynamic_Top',
			offsetX = 0,
			offsetY = -1,
		},
		{
			tilesetId = 2,
			tileId = 821,
			targetLayer = 'Dynamic_Top',
			offsetX = 1,
			offsetY = -1,
        },
		{
			tilesetId = 2,
			tileId = 822,
			targetLayer = 'Dynamic_Top',
			offsetX = 2,
			offsetY = -1,
        },
		{
			tilesetId = 2,
			tileId = 823,
			targetLayer = 'Dynamic_Top',
			offsetX = 3,
			offsetY = -1,
        },
		-- Middle
		{
			tilesetId = 2,
			tileId = 920,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 0,
			offsetY = 0,
		},
		{
			tilesetId = 2,
			tileId = 921,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 1,
			offsetY = 0,
        },
		{
			tilesetId = 2,
			tileId = 922,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 2,
			offsetY = 0,
        },
		{
			tilesetId = 2,
			tileId = 923,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 3,
			offsetY = 0,
        },
        -- Bottom
		{
			tilesetId = 2,
			tileId = 1020,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 0,
			offsetY = 1,
        },
		{
			tilesetId = 2,
			tileId = 1021,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 1,
			offsetY = 1,
        },
		{
			tilesetId = 2,
			tileId = 1022,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 2,
			offsetY = 1,
        },
		{
			tilesetId = 2,
			tileId = 1023,
			targetLayer = 'Dynamic_Bottom',
			offsetX = 3,
			offsetY = 1,
        },
    },
}

local sounds = {
	-- Sounds.swordsClashing1,
}

--- Called when the structure is created in the world
--- @param structure Structure
--- @param builders Unit[]
function STRUCTURE:onSpawn(structure, builders)
    structure.isSelectable = true
end

--- Returns whether the structure can be built by the faction. Resources are checked
--- before this function is called.
--- @param faction Faction
--- @return boolean
function STRUCTURE:canBeBuiltByFaction(faction)
	return true
end

-- TODO: Start of mostly copied from TownHall
--- Called every time the structure updates (See GameConfig.structureUpdateTimeInSeconds)
--- @param structure Structure
function STRUCTURE:onTimedUpdate(structure)
	local faction = structure:getFaction()
    local units = faction:getUnits()
	local housing = faction:getResourceInventory():getValue('housing')

	if (#units >= housing or not structure.lastUnitGenerationTime) then
		structure.lastUnitGenerationTime = nil

		return
	end

    structure.lastUnitGenerationTime = structure.lastUnitGenerationTime + GameConfig.structureUpdateTimeInSeconds

	if (structure.lastUnitGenerationTime < GameConfig.structureUnitGenerationTimeInSeconds) then
		return
	end

    structure.lastUnitGenerationTime = 0

    self:generateUnit(structure)
end

--- Generates a unit
--- @param structure Structure
function STRUCTURE:generateUnit(structure)
	local faction = structure:getFaction()
    local units = faction:getUnits()
	local housing = faction:getResourceInventory():getValue('housing')

	if (#units >= housing) then
		return
	end

    local x, y = structure:getFreeTileNearby()

    if (not x or not y) then
        print('No free tile found around the town hall.')
        return
    end

	faction:spawnUnit(
        UnitTypeRegistry:getUnitType('warrior'),
        x, y
	)
end

--- Draws how much progress has been made generating a unit
--- @param structure Structure
--- @param x number
--- @param y number
--- @param radius number
function STRUCTURE:drawUnitProgress(structure, x, y, radius)
	love.graphics.drawProgressCircle(
		x,
		y,
		radius,
		structure.lastUnitGenerationTime / GameConfig.structureUnitGenerationTimeInSeconds)

	-- Draw the unit icon over the progress circle
	local padding = Sizes.padding()
	local iconWidth = radius * 2 - padding * 2
	local iconHeight = radius * 2 - padding * 2

	love.graphics.setColor(1, 1, 1)
	UnitTypeRegistry:getUnitType('warrior'):drawHudIcon(nil, x - radius + padding, y - radius + padding, iconWidth, iconHeight)
end

--- Called after the structure is drawn on screen
--- @param structure Structure
--- @param minX number
--- @param minY number
--- @param maxX number
--- @param maxY number
function STRUCTURE:postDrawOnScreen(structure, minX, minY, maxX, maxY)
    if (structure.lastUnitGenerationTime) then
        local x = minX + (maxX - minX) * .5
        local y = minY + (maxY - minY) * .5
        local radius = (maxX - minX) * .2

        self:drawUnitProgress(structure, x, y, radius)
    end
end
-- TODO: End of copied from TownHall

--- Gets the actions that the unit can perform
--- Should always return the same actions, but the actions may be disabled or with different progress
--- @param selectedInteractable Interactable
--- @return table
function STRUCTURE:getActions(selectedInteractable)
    local ACTION_TRAIN = {}
    ACTION_TRAIN.text = 'Train Warrior'
    ACTION_TRAIN.icon = 'assets/images/icons/train.png'
    -- ACTION_TRAIN.isEnabled = false

    function ACTION_TRAIN:onRun(selectionOverlay)
		selectedInteractable.lastUnitGenerationTime = 0
    end

    return {
        ACTION_TRAIN
    }
end

return STRUCTURE
