--- Forces the game to only call a certain amount of actions per second.
--- @class Stagger
--- @field maxPerSecond number # The maximum amount of actions to call per second
local Stagger = DeclareClass('Stagger')

local staggerQueue = table.Queue({})

--- Initializes the stagger
--- @param config table
function Stagger:initialize(config)
    assert(config.maxPerSecond, 'Stagger must have a maxPerSecond set.')

    table.Merge(self, config)

    self.callbacksThisSecond = 0
	self.nextSecondAt = love.timer.getTime() + GameConfig.timeInSeconds(1)()
end

--- Called every frame to process staggered actions
--- @param deltaTime number
function Stagger:update(deltaTime)
	if (self.nextSecondAt < love.timer.getTime()) then
		self.callbacksThisSecond = 0
		self.nextSecondAt = love.timer.getTime() + GameConfig.timeInSeconds(1)()
	end

	while (self.callbacksThisSecond < self.maxPerSecond and not staggerQueue:isEmpty()) do
		local callback = staggerQueue:dequeue()
		callback()
		self.callbacksThisSecond = self.callbacksThisSecond + 1
	end
end

--- Adds a callback to the stagger queue
--- @param callback function
function Stagger:stagger(callback)
    staggerQueue:enqueue(callback)
end

return Stagger
