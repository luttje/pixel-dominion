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

Sounds.musicMain = newSource('leohpaz/plain_sight_music.ogg', 'stream')
Sounds.musicMain:setVolume(0.2)
Sounds.musicMain:setLooping(true)

Sounds.treeRustling1 = cutify(newSource('leohpaz/02_tree_rustling_1.ogg'))
Sounds.treeRustling2 = cutify(newSource('leohpaz/02_tree_rustling_2.ogg'))
Sounds.treeRustling3 = cutify(newSource('leohpaz/02_tree_rustling_3.ogg'))
Sounds.treeRustling4 = cutify(newSource('leohpaz/02_tree_rustling_4.ogg'))

-- Sounds.stoneMining1 = cutify(newSource('leohpaz/01_chest_open_1.ogg')) -- sounds too much like a chest opening
Sounds.stoneMining2 = cutify(newSource('leohpaz/01_chest_open_2.ogg'))
Sounds.stoneMining3 = cutify(newSource('leohpaz/01_chest_open_3.ogg'))
Sounds.stoneMining4 = cutify(newSource('leohpaz/01_chest_open_4.ogg'))

Sounds.farming1 = cutify(newSource('leohpaz/01_bush_rustling_1.ogg'))
Sounds.farming2 = cutify(newSource('leohpaz/01_bush_rustling_2.ogg'))
Sounds.farming3 = cutify(newSource('leohpaz/01_bush_rustling_3.ogg'))

return Sounds
