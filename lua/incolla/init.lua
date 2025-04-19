local M = {}

local uv = vim.loop
local level = vim.log.levels

local config = require("incolla.config")
local clipboard = require("incolla.clipboard")
local fsutils = require("incolla.fsutils")

--- Wrapper around vim.notify
---
---@param msg string: Log message
---@param lvl number: One of the values from vim.log.levels
local notify = function(msg, lvl)
    vim.notify(string.format("[Incolla]: %s", msg), lvl)
end

-- Write text in the current buffer
--
--@param text string: Text to be written in the current buffer
local write_text = function(text)
    local pos = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line()
    local nline = line:sub(0, pos) .. text .. line:sub(pos + 1)
    vim.api.nvim_set_current_line(nline)
end

--- Setup function to be run by user. Configures incolla.nvim
---
--- Usage:
--- <code>
--- require('incolla').setup{
---   defaults = {
---     -- Configuration for incolla.nvim goes here:
---     -- key = value,
---     -- ..
---   },
--- }
--- </code>
---@param opts table: Configuration opts.
M.setup = function(opts)
    opts = opts or {}

    if opts.default then
        error "'default' is not a valid value for setup. See 'defaults'"
    end

    config.set(opts)
end



--- Main incolla.nvim function
M.incolla = function()
    if vim.bo.readonly then
        notify("Buffer is readonly", level.WARN)
        return
    end

    local clip = clipboard.get_info()
    if clip.Type == clipboard.Content.UNSUPPORTED then
        notify("Unsupported clipboard content", level.WARN)
        return
    end

    -- Get configuration by filetype
    local ftconfig = config.get(vim.bo.filetype)

    -- Compute filename
    local configured_name = ftconfig.img_name()
    assert(type(configured_name) == "string")
    -- Use original name if FURL
    local file_name = (clip.Type == clipboard.Content.FURL) and
                        vim.fn.fnamemodify(clip.Path, ":t"):gsub("%s", "") or
                        configured_name .. clip.Ext


    -- Ask user for filename
    local fname = vim.fn.input("Enter filename: ", "", "file")
    notify(string.format("Filename chosen: %s", fname), level.INFO)
    if fname ~= nil and fname ~= "" then
        file_name = fname .. clip.Ext
    end

    -- Compute destination path
    -- NOTE: It's always relative to *the file open in the current buffer*
    local imgdir = ftconfig.img_dir
    local dst_path = string.format("%s/%s/%s", vim.fn.expand('%:p:h'), imgdir, file_name)

    if fsutils.file_exists(dst_path) then
        notify("File already exists at destination path", level.WARN)
        return
    end

    -- Create directory if missing
    local dir_path = vim.fn.fnamemodify(dst_path, ":p:h")
    fsutils.create_dir(dir_path)

    if clip.Type == clipboard.Content.IMAGE then
        -- Write new file to disk
        notify("Copy from clipboard", level.INFO)
        clipboard.save_to(dst_path)
    elseif clip.Type == clipboard.Content.FURL then
        -- Copy file to destination
        notify("Copy from file url", level.INFO)
        assert(uv.fs_copyfile(clip.Path, dst_path))
    end

    -- Add text at current position using relative path
    local rel_path = string.format("./%s/%s", imgdir, file_name)
    local text = string.format(ftconfig.affix, rel_path)
    write_text(text)
end

return M
