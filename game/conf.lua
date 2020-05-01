-- the LOVE config file, loads the game properties
-- and applies them to the LOVE config values, as
-- well as sets some globals.

-- loading the properties
local properties = require('preload')

function love.conf(t)
    t.identity = properties.name
    t.version = properties.loveVersion

    t.window.title = properties.name .. " (" .. properties.version .. ")"
    t.window.resizable = true
    t.window.width = _properties.width
    t.window.height = _properties.height
end