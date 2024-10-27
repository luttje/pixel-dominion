local RESOURCE = {}

RESOURCE.id = 'housing'
RESOURCE.name = 'Housing'
RESOURCE.orderWeight = 5

RESOURCE.imagePath = 'assets/images/resources/housing.png'
RESOURCE.defaultValue = 5

--- Formats the value of the resource for display
--- @param faction Faction
--- @param value number
--- @return string|number
function RESOURCE:formatValue(faction, value)
	local units = faction:getUnits()

	return ('%d/%d'):format(#units, value)
end

return RESOURCE
