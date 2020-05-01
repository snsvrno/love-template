-- project settings, for use with scripts and tools

return {
    -- build options
    build = {
        -- building aseprite files, takes .ase and .aseprite files and 
        -- generates a lua sprite sheet along with a png.
        asepriteconvert = { src = "assets", dest = "game/sprites", verbose = true },
    },

    -- different hooks, need to be setup in the project repo
    -- in order for these to actually do anything.
    git = {
        -- precommit, when you commit something, it will run these before giving you the message.
        precommit = {
            assetmanager = { folder = "assets", file = ".assets/assets", repository = ".assets/", verbose = true, func = "store" }
        },

        -- checkout, will run these after you checkout something
        checkout = {
            assetmanager = { folder = "assets", file = ".assets/assets", repository = ".assets/", verbose = true, func = "restore" }
        }
    }
    
}