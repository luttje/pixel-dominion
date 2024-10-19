--- Can be used as a property in your classes to listen for, and trigger events.
---
--- @class EventManager
---
--- @field listeners table<string, function[]>
---
--- @field target any The target this EventManager is attached to.
--- @field bubbleTo EventManager A parent EventManager to bubble events to.
--- @field isMuted boolean Whether the EventManager is muted.
---
local EventManager = DeclareClass('EventManager')

--[[
	The Event class.
--]]

--- Represents a fired event.
--- @class Event
---
--- @field name string
--- @field target any The target that the event was fired on.
--- @field data any[] The arguments that were passed to the event.
--- @field isPropagationStopped boolean Whether the event has been stopped from bubbling up.
EventManager.Event = DeclareClass('EventManager.Event')

--- Creates a new Event.
--- @param config table
function EventManager.Event:initialize(config)
	assert(config.name, 'Event name is required.')
	assert(config.target, 'Event target is required.')

	self.data = {}

	self.isPropagationStopped = false

	table.Merge(self, config)
end

--- Stops the event from bubbling up.
function EventManager.Event:stopPropagation()
	self.isPropagationStopped = true
end

--[[
	The EventManager class.
--]]

--- Creates a new EventManager.
--- @param config table
function EventManager:initialize(config)
	assert(config.target, 'Event target is required.')

	self.listeners = {}

	table.Merge(self, config)
end

--- Adds a listener to the given event.
--- @param event string
--- @param listener function
function EventManager:on(event, listener)
	if (not self.listeners[event]) then
		self.listeners[event] = {}
	end

	table.insert(self.listeners[event], listener)
end

--- Removes a listener from the given event.
--- @param event string
--- @param listener function
--- @return boolean # Whether the listener was removed.
function EventManager:off(event, listener)
	local listeners = self.listeners[event]

	if (listeners) then
		for i, l in ipairs(listeners) do
			if (l == listener) then
				table.remove(listeners, i)
				return true
			end
		end
	end

	return false
end

--- Triggers the given event, calling all listeners.
--- @param event string
--- @param data? table
function EventManager:trigger(event, data)
	if (self.isMuted) then
		return
	end

	local listeners = self.listeners[event]
	local event = EventManager.Event({
		name = event,
		target = self.target,
		data = data or {},
	})

	if (listeners) then
		for _, listener in ipairs(listeners) do
			listener(event)
		end
	end

	if (self.bubbleTo and not event.isPropagationStopped) then
		if (self.bubbleTo.isMuted) then
			return
		end

		self.bubbleTo:trigger(event.name, event.data)
	end
end

--- Mutes the given event for the duration of the callback.
--- @param event string
--- @param callback function
function EventManager:muteDuring(event, callback)
	self.isMuted = true

	callback()

	self.isMuted = false
end

return EventManager
