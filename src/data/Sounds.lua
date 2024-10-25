local Sounds = {}

local function newSource(filePath, type)
	type = type or 'static'
	return love.audio.newSource('assets/sounds/' .. filePath, type)
end

--- Makes a source sound cuter and more 8bit
local function cutify(source)
	source:setVolume(0.8)
	source:setPitch(1.8)
	return source
end

Sounds.treeRustling1 = cutify(newSource('leohpaz/02_tree_rustling_1.wav'))
Sounds.treeRustling2 = cutify(newSource('leohpaz/02_tree_rustling_2.wav'))
Sounds.treeRustling3 = cutify(newSource('leohpaz/02_tree_rustling_3.wav'))
Sounds.treeRustling4 = cutify(newSource('leohpaz/02_tree_rustling_4.wav'))

-- Sounds.stoneMining1 = cutify(newSource('leohpaz/01_chest_open_1.wav')) -- sounds too much like a chest opening
Sounds.stoneMining2 = cutify(newSource('leohpaz/01_chest_open_2.wav'))
Sounds.stoneMining3 = cutify(newSource('leohpaz/01_chest_open_3.wav'))
Sounds.stoneMining4 = cutify(newSource('leohpaz/01_chest_open_4.wav'))

Sounds.farming1 = cutify(newSource('leohpaz/01_bush_rustling_1.wav'))
Sounds.farming2 = cutify(newSource('leohpaz/01_bush_rustling_2.wav'))
Sounds.farming3 = cutify(newSource('leohpaz/01_bush_rustling_3.wav'))

return Sounds
