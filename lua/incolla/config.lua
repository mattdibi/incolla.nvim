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
    -- Per filetype configuration
    for k, v in pairs(opts) do
        M[k] = {
            img_dir = v.img_dir or DEFAULTS.img_dir,
            img_name = v.img_name or DEFAULTS.img_name,
            affix = v.affix or DEFAULTS.affix
        }
    end
end

-- Gets plugin configuration options per filetype.
--
-- If filetype is not set it will return the defaults as they were configured by the user
--
---@param filetype string
---@return table
M.get = function(filetype)
    return M[filetype] ~= nil and M[filetype] or M.defaults
end

return M
