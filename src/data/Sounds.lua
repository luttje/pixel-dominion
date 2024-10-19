local Sounds = {}

local function newSource(filePath, type)
	type = type or 'static'
	return love.audio.newSource('assets/sounds/' .. filePath, type)
end

-- Sounds.cardPlace = newSource('card-place.ogg')
-- Sounds.cardPlace:setVolume(0.4)

-- Sounds.cardUnplace = newSource('card-place.ogg')
-- Sounds.cardUnplace:setVolume(0.2)
-- Sounds.cardUnplace:setPitch(0.3)

-- Sounds.woosh = newSource('woosh-slowed.ogg')

return Sounds
