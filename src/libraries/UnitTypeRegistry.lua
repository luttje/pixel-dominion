--- @class UnitTypeRegistry
local UnitTypeRegistry = DeclareClass('UnitTypeRegistry')

--[[
	UnitRegistration
--]]

--- @class UnitTypeRegistry.UnitAnimation
--- @field quads Quad[] The quads used to render the unit. If multiple quads are provided, the unit will animate between them.
--- @field currentQuadIndex number The index of the current quad being rendered.
UnitTypeRegistry.UnitAnimation = DeclareClass('UnitTypeRegistry.UnitAnimation')

--- Initializes the unit animation
--- @param config table
function UnitTypeRegistry.UnitAnimation:initialize(config)
	config = config or {}

    self.quads = {}
	self.animationTimer = 0
	self.currentQuadIndex = 1

	table.Merge(self, config)

end

--- Gets the quad to render
--- @return Quad
function UnitTypeRegistry.UnitAnimation:getCurrentQuad()
	return self.quads[self.currentQuadIndex]
end

--- Advances the animation to the next frame
--- @return Quad
function UnitTypeRegistry.UnitAnimation:advance()
	self.currentQuadIndex = self.currentQuadIndex + 1

	if self.currentQuadIndex > #self.quads then
		self.currentQuadIndex = 1
	end

	return self:getCurrentQuad()
end

--- @class UnitTypeRegistry.UnitRegistration
--- @field id string The unique id of the unit.
--- @field name string The name of the unit.
--- @field image Image The Image used to render the unit.
--- @field animations table<string, UnitTypeRegistry.UnitAnimation> The animations used to render the unit.
UnitTypeRegistry.UnitRegistration = DeclareClass('UnitTypeRegistry.UnitRegistration')

function UnitTypeRegistry.UnitRegistration:initialize(config)
	assert(config.id, 'Unit id is required.')

	config = config or {}

	table.Merge(self, config)

	self.image = ImageCache:get(self.imagePath)

	-- Create animations for the idle and action states
	local animationConfigs = {
		idle = self.idleImageOffset,
		action = self.actionImageOffset
	}

	self.animations = {}

	for animationName, animationConfig in pairs(animationConfigs) do
		local quads = {}

		for _, offset in ipairs(animationConfig) do
			table.insert(
				quads,
				love.graphics.newQuad(
					offset.x,
					offset.y,
					offset.width or GameConfig.tileSize,
					offset.height or GameConfig.tileSize,
					self.image:getDimensions()))
		end

		self.animations[animationName] = UnitTypeRegistry.UnitAnimation({
			quads = quads
		})
	end
end

--- Draws the given unit at its current position
--- @param unit Unit
--- @param animationName string
function UnitTypeRegistry.UnitRegistration:draw(unit, animationName)
	local animation = self.animations[animationName]

    if (not animation) then
        error('No animation found with name ' .. animationName)
    end

    animation.animationTimer = animation.animationTimer + love.timer.getDelta()

	if (animation.animationTimer >= GameConfig.animationFrameTimeInSeconds()) then
		animation:advance()
		animation.animationTimer = 0
	end

	local quad = animation:getCurrentQuad()
	local x, y = unit.x * GameConfig.tileSize, unit.y * GameConfig.tileSize

	local offsetX, offsetY = unit:getDrawOffset()
	x = x + offsetX
	y = y + offsetY

	-- -- Let's draw a little shadow ellipse under the unit
	-- -- TODO: Make this more dynamic per unit type
	-- love.graphics.setColor(0, 0, 0, 0.5)
	-- love.graphics.ellipse('fill', x + GameConfig.tileSize * .5, y + GameConfig.tileSize, GameConfig.tileSize * .3, GameConfig.tileSize * .3)

	-- TODO: Draw units using a sprite batch for performance
	love.graphics.draw(self.image, quad, x, y)
end

--- Draws the unit hud icon
--- @param unit Unit|nil
--- @param x number
--- @param y number
--- @param width number
--- @param height number
function UnitTypeRegistry.UnitRegistration:drawHudIcon(unit, x, y, width, height)
    local quad = self.animations.idle:getCurrentQuad()

	local imageWidth, imageHeight = GameConfig.tileSize, GameConfig.tileSize
    local scaleX = width / imageWidth
	local scaleY = height / imageHeight

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(self.image, quad, x, y, 0, scaleX, scaleY)
end

--[[
	Registry methods
--]]

local registeredUnitTypes = {}

function UnitTypeRegistry:registerUnitType(unitId, config)
	config = config or {}
	config.id = unitId

	registeredUnitTypes[unitId] = UnitTypeRegistry.UnitRegistration(config)

	return registeredUnitTypes[unitId]
end

function UnitTypeRegistry:removeUnitType(unitId)
	registeredUnitTypes[unitId] = nil
end

function UnitTypeRegistry:getUnitType(unitId)
	return registeredUnitTypes[unitId]
end

function UnitTypeRegistry:getAllUnitTypes()
	local unitConfigs = {}

	for _, config in pairs(registeredUnitTypes) do
		table.insert(unitConfigs, config)
	end

	return unitConfigs
end

return UnitTypeRegistry
