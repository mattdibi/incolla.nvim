local M = {}

local uv = vim.loop
local level = vim.log.levels

local config = require("incolla.config")
local clipboard = require("incolla.clipboard")

--- Wrapper around vim.notify
---
---@param msg string: Log message
---@param lvl number: One of the values from vim.log.levels
local notify = function(msg, lvl)
    vim.notify(string.format("[Incolla]: %s", msg), lvl)
end

--- Check if directory at path exists, if not it creates one
---
---@param dir string: Path of the directory to check
local create_dir = function(dir)
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end
end

--- Check if file at path exists
---
---@param path string: Path to be checked
local file_exists = function(path)
   local f = io.open(path, "r")
   return f ~= nil and io.close(f)
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
---   options = {
---     -- Configuration for incolla.nvim goes here:
---     -- key = value,
---     -- ..
---   },
--- }
--- </code>
---@param opts table: Configuration opts.
M.setup = function(opts)
    opts = opts or {}

    config.set(opts.options)
end

--- Main incolla.nvim function
M.incolla = function()
    local buf = vim.api.nvim_win_get_buf(0)
    if vim.bo[buf].readonly then
        notify("Buffer is readonly", level.WARN)
        return
    end

    local clip = clipboard.get_clipboard_info()
    if clip.Type == clipboard.Content.UNSUPPORTED then
        notify("Unsupported clipboard content", level.WARN)
        return
    end

    -- Compute filename
    local configured_name = config.options.img_name()
    assert(type(configured_name) == "string")
    local file_name = configured_name .. clip.Ext

    -- Compute destination path
    -- NOTE: It's always relative to *the file open in the current buffer*
    local imgdir = config.options.img_dir
    local dst_path = string.format("%s/%s/%s", vim.fn.expand('%:p:h'), imgdir, file_name)

    if file_exists(dst_path) then
        notify("File already exists at destination path", level.WARN)
        return
    end

    -- Create directory if missing
    local dir_path = vim.fn.fnamemodify(dst_path, ":p:h")
    create_dir(dir_path)

    if clip.Type == clipboard.Content.IMAGE then
        -- Write new file to disk
        notify("Copy from clipboard", level.INFO)
        clipboard.save_clipboard_to(dst_path)
    elseif clip.Type == clipboard.Content.FURL then
        -- Copy file to destination
        notify("Copy from file url", level.INFO)
        assert(uv.fs_copyfile(clip.Path, dst_path))
    end

    -- Add text at current position using relative path
    local rel_path = string.format("./%s/%s", imgdir, file_name)
    local text = string.format(config.options.affix, rel_path)
    write_text(text)
end

return M
