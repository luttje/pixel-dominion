require('extensions.require')
require('extensions.math')
require('extensions.table')
require('extensions.classes')
require('extensions.graphics')
require('extensions.timer')
require('extensions.input')

require('enumerations')

RequireDirectory('third-party', SetModuleAsGlobal)
RequireDirectory('libraries', SetModuleAsGlobal)
RequireDirectory('shaders', SetModuleAsGlobal)

RequireDirectory('data', SetModuleAsGlobal)

RequireDirectory('interface-fragments', SetModuleAsGlobal)
RequireDirectory('states', function(fileWithoutExtension, module)
    SetModuleAsGlobal(fileWithoutExtension, module)
	StateManager:registerState(module)
end)
