local RESOURCE = {}

RESOURCE.id = 'food'
RESOURCE.name = 'Food'
RESOURCE.orderWeight = 1
RESOURCE.defaultValue = 20

RESOURCE.imagePath = 'assets/images/resources/food.png'

-- Since food is given an invisible resource instance on farmland (and is thus missing harvestableTilesetInfo), we force it to be harvestable
RESOURCE.forceHarvestable = true

return RESOURCE
