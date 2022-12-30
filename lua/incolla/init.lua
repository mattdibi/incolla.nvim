local M = {}

local uv = vim.loop
local level = vim.log.levels

local config = require("incolla.config")

-- Clipboard content
local Content = {
    IMAGE = "0",
    FURL  = "1",
    UNSUPPORTED = "2"
}

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

--- Check if path points to image file (uses file extension)
---
---@param path string: Path to check
local is_path_to_img = function(path)
    local extension = vim.fn.fnamemodify(path, ":e")
    return extension == "png" or
           extension == "jpg" or
           extension == "jpeg" or
           extension == "webp"
end

--- Get clipboard content informations using osascript
---@return string
local osascript_get_clip_content = function()
    local clip_info = tostring(io.popen('osascript -e "clipboard info"'):read())
    -- Retrieve header info (i.e. up until the first ",")
    local trimmed_info = clip_info:match("[^,]+")
    return trimmed_info
end

--- Get clipboard POSIX path using osascript
---@return string
local osascript_get_clip_path = function()
    local clip_path = tostring(io.popen('osascript -e "POSIX path of (the clipboard as «class furl»)"'):read())
    -- Remove newlines from path
    clip_path = clip_path:gsub("[\n\r]", "")
    return clip_path
end

--- Get information about clipboard content
---@return table: Table containing the Content, Ext and Path
local get_clipboard_info = function()
    local reported_type = osascript_get_clip_content()

    if reported_type:find("PNGf") or reported_type:find("TIFF") then
        return { Type = Content.IMAGE, Path = "" , Ext = ".png"}
    end

    if reported_type:find("furl") then
        local clip_path = osascript_get_clip_path()

        if is_path_to_img(clip_path) then
            local extension = "." .. vim.fn.fnamemodify(clip_path, ":e")
            return { Type = Content.FURL, Path = clip_path, Ext = extension }
        end
    end

    return { Type = Content.UNSUPPORTED, Path = "", Ext = "" }
end

-- Generate random string for temporary file
local generate_random_string = function()
    math.randomseed(os.time())
    local random = "incolla_"
    for _ = 1, 20 do
        random = random .. string.char(math.random(97, 97 + 25))
    end

    return random
end

-- Save image from clipboard to disk
--
---@param dst_path string: Path where the image will be saved to
local save_clipboard_to = function(dst_path)
    -- Generate random tmp file. We need to do this because
    -- osascript requires folder and filename but we want to
    -- use only a path as function parameter
    local tmpdir = uv.os_tmpdir()
    local randname = generate_random_string()
    local tmp_path = string.format("%s/%s", tmpdir, randname)

    -- Save image as PNG from clipboard to tmp_path
    local clip_command = 'osascript' ..
            ' -e "tell application \\"System Events\\" to' ..
            ' write (the clipboard as «class PNGf») to' ..
            ' (make new file at folder \\"' .. tmpdir .. '\\"' ..
            ' with properties {name:\\"'.. randname .. '\\"})"'
    os.execute(clip_command)

    assert(uv.fs_copyfile(tmp_path, dst_path))
    assert(os.remove(tmp_path))
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

    local clip = get_clipboard_info()
    if clip.Type == Content.UNSUPPORTED then
        notify("Unsupported clipboard content", level.WARN)
        return
    end

    local file_name = config.options.img_name() .. clip.Ext
    local imgdir = config.options.img_dir

    -- Compute destination path
    -- NOTE: It's always relative to *the file open in the current buffer*
    local dst_path = string.format("%s/%s/%s", vim.fn.expand('%:p:h'), imgdir, file_name)

    if file_exists(dst_path) then
        notify("File already exists at destination path", level.WARN)
        return
    end

    -- Create directory if missing
    local dir_path = vim.fn.fnamemodify(dst_path, ":p:h")
    create_dir(dir_path)

    if clip.Type == Content.IMAGE then
        -- Write new file to disk
        notify("Copy from clipboard", level.INFO)
        save_clipboard_to(dst_path)
    elseif clip.Type == Content.FURL then
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
