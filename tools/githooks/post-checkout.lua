-- replace the post-checkout hook file with this
--[[
    #!/bin/sh

    lua tools/githooks/post-checkout.lua
]]

local projectSettings = require('project')
local scriptRequirePath = "tools.scripts."

projectSettings.git = projectSettings.git or { }
projectSettings.git.postcheckout = projectSettings.git.postcheckout or { }

for scriptName, arguments in pairs(projectSettings.git.postcheckout) do
    
    local requirePath = scriptRequirePath .. scriptName
    local result, script = pcall(require,requirePath);
    if not result then
        print("cannot find postcheckout script '".. scriptName .. "', looking for it here: '" .. requirePath)
    else
        script(arguments)
    end

end