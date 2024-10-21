local Resources = {}

function Resources:registerResources()
	ResourceTypeRegistry:registerResourceType('food', {
        name = 'Food',
		imagePath = 'assets/images/resources/food.png'
	})

	ResourceTypeRegistry:registerResourceType('wood', {
        name = 'Wood',
        imagePath = 'assets/images/resources/wood.png',
	})

	ResourceTypeRegistry:registerResourceType('stone', {
        name = 'Stone',
		imagePath = 'assets/images/resources/stone.png'
	})

	ResourceTypeRegistry:registerResourceType('gold', {
        name = 'Gold',
		imagePath = 'assets/images/resources/gold.png'
	})

	ResourceTypeRegistry:registerResourceType('housing', {
        name = 'Housing',
        imagePath = 'assets/images/resources/housing.png',
		defaultValue = 5,
		formatValue = function(value)
            local units = CurrentPlayer:getFaction():getUnits()

			return ('%d/%d'):format(#units, value)
		end
	})
end

return Resources
