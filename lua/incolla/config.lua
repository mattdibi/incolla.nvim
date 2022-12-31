local M = {}

-- Default configuration options
local DEFAULTS = {
    img_dir = "imgs",
    img_name = function()
        return os.date("IMG-%d-%m-%Y-%H-%M-%S")
    end,
    affix = "%s",
}

-- Configuration options table
M.defaults = DEFAULTS

-- Sets plugin configuration options
--
---@param opts table: Table containing configuration options
M.set = function(opts)
    -- Defaults
    M.defaults.img_dir = opts.defaults.img_dir or DEFAULTS.img_dir
    M.defaults.img_name = opts.defaults.img_name or DEFAULTS.img_name
    M.defaults.affix = opts.defaults.affix or DEFAULTS.affix

    -- Per filetype configuration
    for k, v in pairs(opts) do
        if k == "defaults" then goto continue end

        M[k] = {
            options = {
                img_dir = v.options.img_dir or DEFAULTS.img_dir,
                img_name = v.options.img_name or DEFAULTS.img_name,
                affix = v.options.affix or DEFAULTS.affix
            }
        }

        ::continue::
    end
end

-- Gets plugin configuration options per filetype.
--
-- If filetype is not set it will return the defaults as they were configured by the user
--
---@param filetype string
---@return table
M.get = function(filetype)
    return M[filetype] ~= nil and M[filetype].options or M.defaults
end

return M
