-- build script, looks at the properties lua file in the 
-- root and runs all the scripts that are named
local projectSettings = require('project').build
local scriptRequirePath = "tools.scripts."

for scriptName, settings in pairs(projectSettings) do
    local requirePath = scriptRequirePath .. scriptName
    local result, script = pcall(require,requirePath);
    if not result then
        print("cannot find build script '".. scriptName .. "', looking for it here: '" .. requirePath)
    else
        script(settings)
    end
end