local M = {}

local DEFAULTS = {
    img_dir = "imgs",
    affix = "![](%s)",
}

M.options = {
    img_dir = "imgs",
    affix = "![](%s)",
}

M.set = function(opts)
    M.options.img_dir = opts.img_dir or DEFAULTS.img_dir
    M.options.affix = opts.affix or DEFAULTS.affix
end

return M
