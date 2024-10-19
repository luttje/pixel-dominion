--- Represents a collection of interface elements that can be added to in
--- onSetupInterface and updated and drawn in performUpdate and performDraw.
--- @class InterfaceFragmentContainer
---
--- @field ownerFragment InterfaceFragment # The parent that the container is attached to (used for relative anchoring)
---
--- @field interfaceFragments InterfaceFragment[]
---
local InterfaceFragmentContainer = DeclareClass('InterfaceFragmentContainer')

--- Creates a new InterfaceFragmentContainer.
--- @param config? table
function InterfaceFragmentContainer:initialize(config)
	config = config or {}

	self.interfaceFragments = {}

	table.Merge(self, config)
end

--- Adds a InterfaceFragment to the container.
--- @param fragment InterfaceFragment
--- @return InterfaceFragment # The added fragment.
function InterfaceFragmentContainer:add(fragment)
	fragment:setParentContainer(self)

	table.insert(self.interfaceFragments, fragment)

	return fragment
end

--- Adds multiple InterfaceFragments to the container.
--- @param fragments InterfaceFragment[]
function InterfaceFragmentContainer:addMultiple(fragments)
	for _, fragment in ipairs(fragments) do
		self:add(fragment)
	end
end

--- Returns all InterfaceFragments in the container.
--- @return InterfaceFragment[] # All InterfaceFragments in the container.
function InterfaceFragmentContainer:getAll()
	return self.interfaceFragments
end

--- Removes a InterfaceFragment from the container.
--- @param fragment InterfaceFragment
function InterfaceFragmentContainer:remove(fragment)
	for i, f in ipairs(self.interfaceFragments) do
		if (f == fragment) then
			table.remove(self.interfaceFragments, i)
			break
		end
	end
end

--- Calls a method on all InterfaceFragments in the container
--- that have the method.
--- @param methodName string
--- @vararg any
function InterfaceFragmentContainer:callMethod(methodName, ...)
	for _, fragment in ipairs(self.interfaceFragments) do
		if (fragment[methodName]) then
			fragment[methodName](fragment, ...)
		end
	end
end

--- Gets the height of all fragments until the given index.
--- @param index? number The index to calculate the height until (last by default).
--- @return number # The height of all fragments until the given index.
function InterfaceFragmentContainer:getHeightUntilIndex(index)
	index = index or #self.interfaceFragments

	local height = 0

	for i = 1, index do
		local fragmentWidth, fragmentHeight = self.interfaceFragments[i]:getSize()
		height = height + fragmentHeight + Sizes.margin() -- TODO: Make margin not hard-coded
	end

	return height
end

--- Updates all InterfaceFragments in the container.
--- @param deltaTime number
function InterfaceFragmentContainer:update(deltaTime)
	self:callMethod('update', deltaTime)
end

--- Draws all InterfaceFragments in the container.
function InterfaceFragmentContainer:draw()
	self:callMethod('draw')
end

return InterfaceFragmentContainer
