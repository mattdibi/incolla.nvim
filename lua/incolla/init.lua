local M = {}

local uv = vim.loop
local level = vim.log.levels

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

--- Check if path points to image file (uses file extension)
---
---@param path string: Path to check
local is_path_to_img = function(path)
    return path:find(".png") ~= nil or path:find(".jpg") ~= nil or path:find(".jpeg") ~= nil
end

--- Get information about clipboard content
---@return table: Table containing the Content, Ext and Path
local get_clipboard_info = function()
    -- Retrieve clipboard info
    local clip_info = tostring(io.popen('osascript -e "clipboard info"'):read())
    -- Retrieve header info
    local reported_type = clip_info:match("[^,]+")

    if reported_type:find("PNGf") or reported_type:find("TIFF") then
        return { Type = Content.IMAGE, Path = "" , Ext = ".png"}
    elseif reported_type:find("furl") then
        -- If clipboard type is file url, check it points to an actual image
        local clip_path = tostring(io.popen('osascript -e "POSIX path of (the clipboard as «class furl»)"'):read())
        -- Remove newlines from path
        clip_path = clip_path:gsub("[\n\r]", "")

        if is_path_to_img(clip_path) then
            local extension = clip_path:match("^.+(%..+)$")
            return { Type = Content.FURL, Path = clip_path, Ext = extension }
        else
            return { Type = Content.UNSUPPORTED, Path = "", Ext = "" }
        end
    else
        return { Type = Content.UNSUPPORTED, Path = "", Ext = "" }
    end
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

--- Main incolla.nvim function
M.incolla = function()
    local clip = get_clipboard_info()
    if clip.Type == Content.UNSUPPORTED then
        notify("Unsupported clipboard content", level.WARN)
        return
    end

    local buf = vim.api.nvim_win_get_buf(0)
    if vim.bo[buf].readonly then
        notify("Buffer is readonly", level.WARN)
        return
    end

    local file_name = os.date("IMG-%d-%m-%Y-%H-%M-%S") .. clip.Ext -- TODO: Configurable
    local imgdir = "imgs" -- TODO: Configurable

    local dir_path = string.format("%s/%s", vim.fn.expand('%:p:h'), imgdir)
    local dst_path = string.format("%s/%s/%s", vim.fn.expand('%:p:h'), imgdir, file_name)

    -- Create directory if missing
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
    local text = string.format("![%s](%s)", file_name, rel_path)
    write_text(text)
end

return M
