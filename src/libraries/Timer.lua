--- @class Timer
local Timer = DeclareClass('Timer')

local registeredTimers = {}

function Timer:initialize(config)
	assert(config.callback, 'Timer callback is required.')
	assert(config.interval, 'Timer interval is required.')
	assert(config.repeatCount, 'Timer repeatCount is required.')

	table.Merge(self, config)

	self.timePassed = 0

	table.insert(registeredTimers, self)
end

function Timer:update(deltaTime)
	self.timePassed = self.timePassed + deltaTime

	if (self.timePassed < self.interval) then
		return
	end

	self.callback(self)

	if (self.repeatCount > 0) then
		self.repeatCount = self.repeatCount - 1
	else
		-- Timer is done, remove it
		self:destroy()
	end

	self.timePassed = 0
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
