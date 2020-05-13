-- creates scaffold to use the hooks, WARNING this will erase whatever
-- is in there already, so make sure you know what you are doing before
-- running this script. should only be run once at the beginning of the
-- project to connect the project's hooks

require('lfs')

local function getBaseName(filepath)
    -- strips the base name from the path
    return string.match(filepath, "^.+[/\\](.+)%..+$")
end

local gitHookText = "#!/bin/sh\n\nlua tools/githooks/"

local githookpath = ".git/hooks"
local projecthookpath = "tools/githooks"

-- checks if the githook folder is found.
if lfs.attributes(githookpath, "mode") == "directory" then
    
    for file in lfs.dir(projecthookpath) do
        local fullpath = projecthookpath .. "/" .. file
        if file ~= "." and file ~= ".." and lfs.attributes(fullpath,"mode") == "file" then
            -- a valid file, now checks if its a lua file
            if #file > 4 then if file:sub(#file-3,#file) == ".lua" then
                local filename = getBaseName(fullpath)
                print("hooking " .. filename)

                -- make the hook file
                local filebuffer = io.open(githookpath .. "/" .. filename, "w")
                filebuffer:write(gitHookText .. file)
                filebuffer:close()

            end end
        end
    end
else
    print('folder is not a git repository')
end