-- replace the pre-commit hook file with this
--[[
    #!/bin/sh

    lua tools/githooks/pre-commit.lua
]]

local projectSettings = require('project')
local scriptRequirePath = "tools.scripts."

projectSettings.git = projectSettings.git or { }
projectSettings.git.precommit = projectSettings.git.precommit or { }

for scriptName, arguments in pairs(projectSettings.git.precommit) do
    
    local requirePath = scriptRequirePath .. scriptName
    local result, script = pcall(require,requirePath);
    if not result then
        print("cannot find precommit script '".. scriptName .. "', looking for it here: '" .. requirePath)
    else
        local filesToCommit = script(arguments)
        for _, file in pairs(filesToCommit or { }) do
            os.execute("git add -f " .. file)
        end
    end

end