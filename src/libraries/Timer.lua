--- @class Timer
local Timer = DeclareClass('Timer')

local registeredTimers = {}

function Timer:initialize(config)
	assert(config.callback, 'Timer callback is required.')
	assert(config.interval, 'Timer interval is required.')
	assert(config.repeatCount, 'Timer repeatCount is required.')

	table.Merge(self, config)

	self.nextCallbackAt = nil

	table.insert(registeredTimers, self)
end

function Timer:update(deltaTime)
    if (self.nextCallbackAt == nil) then
        self.nextCallbackAt = love.timer.getTime() + (self.interval / GameConfig.gameSpeed)
    end

	if (self.nextCallbackAt > love.timer.getTime()) then
		return
	end

	self.callback(self)

	if (self.repeatCount > 0) then
		self.repeatCount = self.repeatCount - 1
	else
		-- Timer is done, remove it
		self:destroy()
	end

	self.nextCallbackAt = nil
end

function Timer:destroy()
	for k, timer in ipairs(registeredTimers) do
		if (timer == self) then
			table.remove(registeredTimers, k)
			break
		end
	end
end

function Timer.simple(interval, callback)
	return Timer({
		interval = interval,
		repeatCount = 0,
		callback = callback
	})
end

function Timer.updateAll(deltaTime)
	for k, timer in ipairs(registeredTimers) do
		timer:update(deltaTime)
	end
end

return Timer
