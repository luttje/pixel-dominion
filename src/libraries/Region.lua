local Region = DeclareClass('Region')

function Region:initialize(config)
    config = config or {}

    assert(config.name, 'Region name is required.')
	assert(config.worldData, 'Region world data is required.')

	-- The name of the region.
	self.name = ''

	-- The description of the region.
	self.description = ''

	table.Merge(self, config)
end

--[[
	Getters/Setters
--]]

--- Returns the name of the region.
--- @return string
function Region:getName()
    return self.name
end

return Region
