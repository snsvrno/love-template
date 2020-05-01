-- asset management script, intent is to keep track of the assets
-- such that different commits will have the raw assets available
-- that were used to build the game assets.

local md5 = require('tools.scripts.lib.md5')
require('lfs')

-- for outputting stuff to the console, defaults to off / false
local outputText = false

local function getBaseName(filepath)
    -- strips the base name from the path
    return string.match(filepath, "^.+[/\\](.+)%..+$")
end

local function getExtension(filepath)
    -- strips the extension from the path
    return string.match(filepath, "^.+[/\\].+%.(.+)$")
end

local function getFiles(path)
end

local function getApplicableFiles(path)
    -- gets a list of all the files that should be processed for backup.
    local foundFiles = { }

    for file in lfs.dir(path) do
        local fullPath = path .. "/" .. file
        if lfs.attributes(fullPath, "mode") == "file" then
            table.insert(foundFiles, fullPath)
        elseif file ~= "." and file ~= ".." and lfs.attributes(fullPath, "mode") == "directory" then
            local subfolder = getApplicableFiles(fullPath)
            for _,sub in pairs(subfolder) do
                table.insert(foundFiles, sub)
            end
        end
    end

    return foundFiles
end

local function generateHash(filepath)
    -- creates a longform hash for the content of the file.

    local raw = io.open(filepath, "rb")
    local content = raw:read("*all")
    raw:close()
    return md5.sumhexa(content)
end

local function copy(from,to)
    -- copies a binary file from one spot to another spot.

    local raw = io.open(from, "rb")
    local content = raw:read("*all")
    raw:close()
    
    local newFile = io.open(to, "wb")
    newFile:write(content)
    newFile:close()
end

local function defaults(args)
    -- injects the given argument table with the default arguments.

    local defaultValues = { watch = "assets", file = ".assets/assets", repository = ".assets/", verbose = false, files = { } }

    for i,v in pairs(defaultValues) do
        if args[i] == nil then args[i] = v end
    end

    return args
end

local function store(args)
    -- the store function, will scan for the requested files and 
    -- process them

    local filesCurrentlyLoaded = { }

    local filesToProcess = getApplicableFiles(args.watch)
    for _, file in pairs(filesToProcess) do
        -- gets the hash
        local hash = generateHash(file)

        -- makes the repository name
        local storedName = getBaseName(file) .. "." .. hash .. "." .. getExtension(file)
        local storedPath = args.repository .. "/" .. storedName

        -- copies the file to the repository if it doesn't already exist.
        if not lfs.attributes(storedPath) then
            copy(file, storedPath)        else
        end

        if outputText then print("storing '" .. file .. "' => '" .. storedName .. "'") end

        -- adds this file to the list of files that should
        -- be enabled in the current commit

        filesCurrentlyLoaded[file] = storedName
        -- print(file, hash)
    end

    -- creates the currents file
    do
        -- makes it into a lua file, for ease of 
        -- importing and parsing, no one should be editing this
        -- manually so we shouldn't have any issues.
        local content = "return {\n"
        for file, hash in pairs(filesCurrentlyLoaded) do
            content = content .. "  [\"" .. file .. "\"] = \"" .. hash .. "\"\n" 
        end
        content = content .. "}"

        local file = io.open(args.file, "w")
        file:write(content)
        file:close()
    end

end

local function restore(args)
    -- will read the `file` and restore the assets that are defined. 
    -- it will not remove things that aren't suppose to be there, since'
    -- it doesn't have full control of the project folders.
    local foundfile, files = pcall(loadfile,args.file)
    
    if not foundfile then 
        print("assetmanager cannot find the asset file: " .. tostring(args.file))
        return
    end

    for dest,file in pairs(files()) do
        if outputText then print("restoring '" .. file .. "' => '" .. dest .. "'") end
        copy(args.repository .. "/" .. file,dest)
    end
end

return function(args)
    
    -- sets the defaults in case we don't have anything
    defaults(args)

    if args.verbose then outputText = true end

    -- first we check if the bank / repo exists, and 
    -- creates it if it doesn't
    if not lfs.attributes(args.repository) then lfs.mkdir(args.repository) end

    if args.func == "store" then
        store(args)
        -- the file to save with the commits
        return { args.file }
    elseif args.func == "restore" then
        restore(args)
    else
        print('assetmanager.lua does not understand func: ' .. tostring(arg.func))
    end

end