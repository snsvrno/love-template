require('lfs')
local ZipWriter = require('ZipWriter') -- must install it with luarocks .. not ideal.

local function mkAllDir(path)
    -- works up the path and attempts to make every folder
    -- in the path working its way from parent to child, so
    -- that all the folders are made.
    -- will not delete or overwrite anything

    local working = ""
    for i=1, #path do
        local char = path:sub(i,i)
        if char == "/" or char == "\\" then
            lfs.mkdir(working)
        end
        working = working .. char
    end
end

local function makeReader(fname)
    -- taken from zipwrite example.

    local f = assert(io.open(fname, 'rb'))
    local chunk_size = 1024
    local desc = { -- `-rw-r-----` on Unix
      istext   = true,
      isfile   = true,
      isdir    = false,
      mtime    = 1348048902, -- lfs.attributes('modification')
      platform = 'unix',
      exattrib = {
        ZipWriter.NIX_FILE_ATTR.IFREG,
        ZipWriter.NIX_FILE_ATTR.IRUSR,
        ZipWriter.NIX_FILE_ATTR.IWUSR,
        ZipWriter.NIX_FILE_ATTR.IRGRP,
        ZipWriter.DOS_FILE_ATTR.ARCH,
      },
    }
    return desc, desc.isfile and function()
      local chunk = f:read(chunk_size)
      if chunk then return chunk end
      f:close()
    end
  end

local function loadIntoArchive(archive, root, folder)

    for file in lfs.dir(folder) do
        if file ~= "." and file ~= ".." then
            local fullPath = folder .. "/" .. file
            if lfs.attributes(fullPath, "mode") == "file" then
                local relativePath; if #root == 0 then relativePath = fullPath
                else relativePath = fullPath:sub(#root+2, #fullPath) end
                archive:write(relativePath, makeReader(fullPath))
            elseif lfs.attributes(fullPath, "mode") == "directory" then
                loadIntoArchive(archive, root, fullPath)
            end
        end
    end
end

local function getFolderBaseName(filepath)
    -- strips the base name from the path
    local base = string.match(filepath, "^.+[/\\](.+)")
    return base or filepath
end

local function createLove(src, dst)
    -- makes the love file, and ignores all the files we don't want,
    -- while also copying library directory indiscriminently. need to
    -- find out a smarter way of doing this so it only takes what is 
    -- being used.

    mkAllDir(dst)
    
    local zip = ZipWriter.new()
    zip:open_stream(assert(io.open(dst,'wb')), true)
    -- adds the base project
    loadIntoArchive(zip, src, src)
    -- adds the library folder
    loadIntoArchive(zip, '', 'libs')
    zip:close()
end

local src = arg[1]
local dst; do
    -- loads the properties if set.
    local properties = loadfile(src .. '/properties.lua')
    -- loads the version if set
    local version; do
        local file = io.open(src .. '/version', 'r')
        if file then
            version = file:read("*all")
            file:close()
        end
    end
    
    dst = "bin/"
    if properties then dst = dst .. properties().type .. "-" end
    dst = dst .. getFolderBaseName(src)
    if version then dst = dst .. "-" .. version end
    dst = dst .. ".love"
end

if src and dst then
    print("packaging '" .. src .. "' to '" .. dst .. "'")
    createLove(src,dst)
end