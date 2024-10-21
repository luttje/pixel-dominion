local RESOURCE = {}

RESOURCE.id = 'housing'
RESOURCE.name = 'Housing'
RESOURCE.orderWeight = 5

RESOURCE.imagePath = 'assets/images/resources/housing.png'
RESOURCE.defaultValue = 5

function RESOURCE:formatValue(value)
	local units = CurrentPlayer:getFaction():getUnits()

	return ('%d/%d'):format(#units, value)
end

return RESOURCE
