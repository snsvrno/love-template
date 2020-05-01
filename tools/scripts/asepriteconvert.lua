-- converts the output of aseprite's json-hash with slices to a lua file
-- for easier loading into love.
local json = require('tools.scripts.lib.json')
local enableOutput = false
require('lfs')

local _validAsepriteExtensions = { ".ase", ".aseprite" }

----------------------------------------------------------------
-- some functions
local function wait()
    -- a wait function so we can wait for a file to be available.
    local t0 = os.clock()
    while os.clock() - t0 <= 1 do end
end

local function _readContentsOfFile(file)
    local f = assert(io.open(file, 'rb'))
    local content = f:read('*all')
    f:close()
    return content
end

local function _writeToFile(file, content)
    local f = assert(io.open(file, 'w+'))
    f:write(content)
    f:close()
end

----------------------------------------------------------------

local function process(source, target)
    -- converts json to lua

    for file in lfs.dir(source) do
        local spriteParts = ""

        -- determines if this is a file we can convert.
        local filename = nil; if #file > 5 then
            if file:sub(#file-4,#file) == ".json" then filename = file:sub(1, #file-5) end
        end

        -- we found a match above and extracted the extension (because we really don't
        -- care and need to rename it with the converted extensions anyway.)
        if filename then
            if enableOutput then print("  ..  found sprite '" .. filename .. "'") end
            local newFile = target .. "/" .. filename .. ".lua"

            local contents = _readContentsOfFile(source .. "/" .. filename .. ".json")
            local decoded = json.decode(contents)
            local newFileText = "return {\n"

            for _,data in pairs(decoded.meta.slices) do
                if #spriteParts == 0 then spriteParts = data.name
                else spriteParts = spriteParts .. ", " .. data.name end

                local text = ""
                -- sprite start
                text = text .. "x = " .. tostring(data.keys[1].bounds.x) .. ", "
                text = text .. "y = " .. tostring(data.keys[1].bounds.y) .. ", "
                -- sprite width and height (size)
                text = text .. "w = " .. tostring(data.keys[1].bounds.w) .. ", "
                text = text .. "h = " .. tostring(data.keys[1].bounds.h) .. ", "
        
                if data.keys[1].pivot then
                -- the center of the sprite (with perspective)
                    text = text .. "cx = " .. tostring(data.keys[1].pivot.x) .. ", "
                    text = text .. "cy = " .. tostring(data.keys[1].pivot.y) .. ", "
                end
        
                if data.keys[1].center then
                    -- the overlap width and height for tiling
                    text = text .. "ow = " .. tostring(data.keys[1].bounds.w - data.keys[1].center.w) .. ", "
                    text = text .. "oh = " .. tostring(data.keys[1].bounds.h - data.keys[1].center.h) .. ", "
                end
        
                -- builds the string
                newFileText = newFileText .. "  [\"" .. data.name .. "\"] = { " .. text .. " },\n"
            end

            newFileText = newFileText .. "}"

            if enableOutput then print("      .. found parts: '" .. spriteParts .. "'") end

            _writeToFile(newFile, newFileText)
        end
    end
end

local function runAseprite(source, working, target)
    local dataOptions = "--format json-hash --list-slices"
    
    for file in lfs.dir(source) do

        -- determines if this is a file we can convert.
        local filename = nil; for _,ext in pairs(_validAsepriteExtensions) do
            if #file > #ext then
                if file:sub(#file-(#ext-1),#file) == ext then filename = file:sub(1, #file-#ext) end
            end
        end

        if filename then
            local asepriteFile = source .. "/" .. filename ..".aseprite"
            local sourceJson = working .. "/" .. filename .. ".json"
            local image = target .. "/" .. filename ..".png"

            -- going to check if we already has an exported json, we need to remove it because
            -- popen doesn't wait, so we could be using the older data here, and not the new
            -- one that is being made from this script
            if lfs.attributes(sourceJson,"mode") then
                os.remove(sourceJson)
            end
            
            -- exports the aseprite
            io.popen("aseprite -b --data " .. sourceJson .. " " .. dataOptions .. " ".. asepriteFile)
            io.popen("aseprite -b " .. asepriteFile .." --save-as " .. image)

            while true do
                if lfs.attributes(sourceJson,"mode") then break
                else wait() end
            end

        end
    end
end

return function(args)
    -- possible args are 
    -- - src : path = source path
    -- - dest : path = destination path
    -- - verbose : bool  = if we should output stuff to console
    -- - working : path = the working folder
    
    args.working = args.working or "tmp"
    if args.verbose == true then enableOutput = true end
    
    if enableOutput then print("building sprites in '" .. args.src .. "'") end
    -- makes the temporary directory
    lfs.mkdir(args.working)
    runAseprite(args.src, args.working, args.dest)
    process(args.working, args.dest)
    if enableOutput then print("building sprites: DONE") end
end