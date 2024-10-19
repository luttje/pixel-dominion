--- Declares a new class, optionally inheriting from a base class.
--- Sourced in part from http://lua-users.org/wiki/SimpleLuaClasses
--- @param name string
--- @param base? table
--- @return table
local function declareClass(name, base)
	local newClass = {}

	if (base) then
		for i, v in pairs(base) do
			newClass[i] = v
		end

		newClass.__base = base
		newClass.getBase = function(self)
            return setmetatable({}, {
				__index = function(baseClassTable, key)
					if (base[key]) then
						if (type(base[key]) == "function") then
							return function(__, ...)
								return base[key](self, ...)
							end
						else
							return base[key]
						end
					else
						error('Base class key not found: "' .. tostring(key) .. '"')
					end
				end
			})
		end
	end

	-- the class will be the metatable for all its objects,
	-- and they will look up their methods in it.
	newClass.__index = newClass
	newClass.__type = name

	-- expose a constructor which can be called by <classname>(<args>)
	local metaTable = {}
	metaTable.__call = function(classTable, ...)
		local newInstance

		if (base) then
			newInstance = base(...)
		else
			newInstance = {}
		end

		setmetatable(newInstance, newClass)

		if (newInstance.initialize) then
            newInstance:initialize(...)
		end

		return newInstance
	end

    newClass.isOfType = function(self, classToCheck)
        local ownMetatable = getmetatable(self)

        while (ownMetatable) do
            if (ownMetatable == classToCheck) then
                return true
            end

            ownMetatable = ownMetatable.__base
        end

        return false
    end

    setmetatable(newClass, metaTable)

	return newClass
end

--[[
	These functions are here to prevent mistakes when declaring classes.
	For example when we declare a class with a base class, we want to make sure
	that the base class is not nil.
	This mistake happened when requiring an entire directory, and assuming the
	base class was loaded before the class that was inheriting from it.
--]]

function DeclareClass(name, base)
	assert(base == nil, "Use DeclareClassWithBase for classes with a base class.")
	return declareClass(name, base)
end

function DeclareClassWithBase(name, base)
	assert(base ~= nil, "Tried to declar a class with a base class, but base class was nil.")
	return declareClass(name, base)
end

local originalType = type

--- Detours the type function to return class types.
--- @param value any
--- @return string
function type(value)
	if (originalType(value) == 'table' and value.__type) then
		return value.__type
	else
		return originalType(value)
	end
end
