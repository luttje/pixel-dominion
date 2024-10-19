--- Shader for world map fog of war
--- @class FogOfWarShader
local FogOfWarShader = {}

local shaderCode = love.filesystem.read('assets/shaders/fog-of-war.glsl')

function FogOfWarShader:makeReady()
    if (self.isInitialized) then
        return
    end

    self.shader = love.graphics.newShader(shaderCode)

    self.isInitialized = true
end

function FogOfWarShader:use(worldX, worldY)
	self:makeReady()

    self.shader:send('current_time', love.timer.getTime())
	self.shader:send('world_coordinates', { worldX, worldY })
    love.graphics.setShader(self.shader)
end

function FogOfWarShader:unuse()
    love.graphics.setShader()
end

return FogOfWarShader
