-- copies a project directory (minus the git folder if exists) into
-- the selected library folder / path.
require('lfs')

local ignoreMatches = { ".git" }

local function getFolderBaseName(filepath)
    -- strips the base name from the path
    return string.match(filepath, "^.+[/\\](.+)")
end

local function copyFile(from,to)
    -- copies a binary file from one spot to another spot.

    local raw = io.open(from, "rb")
    local content = raw:read("*all")
    raw:close()
    
    local newFile = io.open(to, "wb")
    newFile:write(content)
    newFile:close()
end

local function rmDir(directory)
    --recursively deletes a directory.

    for file in lfs.dir(directory) do
        if file ~= "." and file ~= ".." then 
            local fullPath = directory .. "/" .. file
            if lfs.attributes(fullPath, "mode") == "directory" then
                rmDir(fullPath)
            elseif lfs.attributes(fullPath, "mode") == "file" then
                os.remove(fullPath)
            end
        end
    end

    local msg = lfs.rmdir(directory)
    if msg ~= true then print(msg) end
end

local function copyPath(from, to)
    -- copies the path to the new path, uses the .gitignore 
    -- and ignores those files + the .git folder.

    -- deletes the existing folder if it already exists
    
    -- if it exists then delete it.
    if lfs.attributes(to, "mode") then rmDir(to) end

    if lfs.attributes(from, 'mode') == "directory" then
        
        -- makes the base folder
        lfs.mkdir(to)

        for file in lfs.dir(from) do
            local skip = false

            -- skips the this folder and parent folder symbols.
            if file == "." or file == ".." then skip = true end

            for _,pattern in pairs(ignoreMatches) do
                if string.match(file, pattern) then skip = true end
            end

            if not skip then
                local fullPathSrc = from .. "/" .. file
                local fullPathDesc = to .. "/" .. file
                if lfs.attributes(fullPathSrc, "mode") == "directory" then
                    copyPath(fullPathSrc, fullPathDesc)
                elseif lfs.attributes(fullPathSrc, "mode") == "file" then
                    copyFile(fullPathSrc, fullPathDesc)
                end
            end
        end
    end
end

return function(args)
    -- main function, reads the arguments and orchestrates everything

    -- adds custom ignore stuff
    for _, v in pairs(args.ignore or { }) do
        table.insert(ignoreMatches, v)
    end

    local destinationFolder = lfs.currentdir() .. "/" .. args.folder
    for _, library in pairs(args.libraries) do
        print("updating library: " .. tostring(library))
        local sourceFolder = lfs.currentdir() .. "/" .. library
        copyPath(sourceFolder, destinationFolder .. "/" .. getFolderBaseName(library))
    end

end
