local M = {}

-- Default configuration options
local DEFAULTS = {
    img_dir = "imgs",
    img_name = function()
        return os.date("IMG-%d-%m-%Y-%H-%M-%S")
    end,
    affix = "![](%s)",
}

-- Configuration options table
M.options = DEFAULTS

-- Sets plugin configuration options
--
---@param opts table: Table containing configuration options
M.set = function(opts)
    M.options.img_dir = opts.img_dir or DEFAULTS.img_dir
    M.options.img_name = opts.img_name or DEFAULTS.img_name
    M.options.affix = opts.affix or DEFAULTS.affix
end

return M
