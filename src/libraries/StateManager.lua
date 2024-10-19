--- Manages the state the game can be in, like in a menu, or certain game modes.
--- This is a singleton class with a static interface.
--- @class StateManager
local StateManager = {}

local states = {}
local currentState
local previousState

-- If the state is an instance, get the class.
local function ensureStateIsClass(state)
	if (state.instance == nil) then
		return state
	end

	return getmetatable(state.instance)
end

--- Registers and instantiates a state class.
function StateManager:registerState(state)
    local instance = state()

    states[state] = instance

	state.instance = instance
end

function StateManager:setCurrentState(state, ...)
    state = ensureStateIsClass(state)

	assert(states[state], 'State "' .. type(state) .. '" does not exist.')

	previousState = currentState

	if (previousState) then
		previousState:call('onExit', ...)
	end

    currentState = states[state]

    if (not currentState.hasInitialized) then
        currentState:call('onStateInitialize', ...)
    end

	currentState:call('onEnter', ...)

	return currentState
end

--- Get if the given state or state name is the current state.
--- @param state BaseState
--- @return boolean
function StateManager:isCurrentState(state)
	state = ensureStateIsClass(state)

	return currentState == states[state]
end

--- Get if the given state or state name is the previous state.
--- Useful in onEnter methods to check if the previous state was a certain state.
--- @param state BaseState
--- @return boolean
function StateManager:isPreviousState(state)
	state = ensureStateIsClass(state)

	return previousState == states[state]
end

function StateManager:call(methodName, ...)
    assert(currentState, 'No current state set. Use StateManager:setCurrentState() to set a state.')

	-- TODO: Ugly hack for now, but we want a nice way to draw popup states over old states
	if (methodName == 'onDraw' and previousState) then
		previousState:call(methodName, ...)
		-- Draw a dim overlay to show the previous state is still there.
		love.graphics.setColor(0, 0, 0, 0.85)
		love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
	end

    local method = currentState[methodName]

    if (method) then
        method(currentState, ...)
    end
end

--- Set the current state to the given state if the condition state is the current state.
--- @param state BaseState
--- @param conditionState BaseState
--- @vararg any
--- @return boolean # If the state was set.
function StateManager:setCurrentStateIf(state, conditionState, ...)
    if (self:isCurrentState(conditionState)) then
        self:setCurrentState(state, ...)
		return true
    end

	return false
end

return StateManager
