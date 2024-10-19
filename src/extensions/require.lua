local filesystem = love.filesystem

--- Helper for when requiring, to set every returned module as a global variable.
--- @param fileWithoutExtension string
--- @param module any
--- @return any
function SetModuleAsGlobal(fileWithoutExtension, module)
    _G[fileWithoutExtension] = module
	return module
end

--- Requires a directory by loading all files in it.
--- @param path string
--- @param callbackOnRequire? fun(fileWithoutExtension: string, module: any) A callback to call when a module is required.
--- @return table
function RequireDirectory(path, callbackOnRequire)
	local files = filesystem.getDirectoryItems(path)
    local required = {}

    for _, file in ipairs(files) do
		local fileWithoutExtension = file:match('(.+)%..+')
        local fullPath = path .. '/' .. file
		local fileInfo = filesystem.getInfo(fullPath)

		if (fileInfo and fileInfo.type == 'file') then
			local module = require(path:gsub('/', '.') .. '.' .. fileWithoutExtension)

            if (callbackOnRequire) then
				callbackOnRequire(fileWithoutExtension, module)
			end

			required[fullPath] = module
		end
	end

	return required
end
