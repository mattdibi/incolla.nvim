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

--- Check if running on MacOS
local is_mac_os = function()
    local this_os = tostring(io.popen("uname"):read())
    return this_os == "Darwin"
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
local get_clipboard_info = function()
    -- Retrieve clipboard info
    local clip_info = tostring(io.popen('osascript -e "clipboard info"'):read())
    -- Retrieve header info
    local reported_type = clip_info:match("[^,]+")

    if reported_type:find("PNGf") or reported_type:find("TIFF") then
        return { Type = Content.IMAGE, Path = "" }
    elseif reported_type:find("furl") then
        -- If clipboard type is file url, check it points to an actual image
        local clip_path = tostring(io.popen('osascript -e "POSIX path of (the clipboard as «class furl»)"'):read())
        -- Remove newlines from path
        clip_path = clip_path:gsub("[\n\r]", "")

        if is_path_to_img(clip_path) then
            return { Type = Content.FURL, Path = clip_path }
        else
            return { Type = Content.UNSUPPORTED, Path = "" }
        end
    else
        return { Type = Content.UNSUPPORTED, Path = "" }
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

--- Function equivalent to basename in POSIX systems
--
---@param path string: The path string
local basename = function(path)
    local name = string.gsub(path, "(.*/)(.*)", "%2")
    return name
end

--- Main incolla.nvim function
M.incolla = function()
    if not is_mac_os() then
        notify("Unsupported OS", level.ERROR)
        return
    end

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

    -- Create directory if missing
    local file_name

    local current_folder = vim.fn.expand('%:p:h')
    local imgdir = "imgs"

    local target_folder_full_path = current_folder .. "/" .. imgdir
    local target_folder_rel_path = "./" .. imgdir

    create_dir(target_folder_full_path)

    if clip.Type == Content.IMAGE then
        -- Write new file to disk
        notify("Copy from clipboard", level.INFO)
        file_name = os.date("IMG-%d-%m-%Y-%H-%M-%S.png")
        save_clipboard_to(target_folder_full_path .. "/".. file_name)
    elseif clip.Type == Content.FURL then
        -- Copy file to destination
        notify("Copy from file url", level.INFO)
        file_name = basename(clip.Path)
        assert(uv.fs_copyfile(clip.Path, target_folder_full_path .. "/" .. file_name))
    end

    -- Add text at current position using relative path
    local text = string.format("![%s](%s/%s)", file_name, target_folder_rel_path, file_name)
    write_text(text)
end

return M
