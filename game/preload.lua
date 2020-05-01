-- does preprocessing to the properties

-------------------------------------------------------------------
-- for debugging with vscode
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

local function getVersion()
    -- returns the version number (as a string)

    -- looks for the version file
    local version = love.filesystem.read("version")

    -- checks if we have a gitfile
    local gitver = love.filesystem.read("gitver")
    if gitver then version = version .. "-" .. gitver end

    return version
end

--------------------------------------------------------------------
-- loads the base properties (and then the version)
local properties = require('properties')
properties.version = getVersion()

-- loads the game properties into a global variable that everyone can
-- access later
local globalProperties = { }
_G["_properties"] = globalProperties
-- loads all the game properties
for i,v in pairs(properties.game) do globalProperties[i] = v end

return properties