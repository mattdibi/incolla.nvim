local M = {}

-- Clipboard content
local Content = {
    IMAGE = "0",
    FURL  = "1",
    UNSUPPORTED = "2"
}

--- Check if running on MacOS
local is_mac_os = function()
    local this_os = tostring(io.popen("uname"):read())
    return this_os == "Darwin"
end

--- Check if directory at path exists, if not it creates one
---
--@param dir Path of the directory to check
local create_dir = function(dir)
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end
end

--- Check if path points to image file (uses file extension)
---
--@param path Path to check
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


-- Copy image from clipboard to disk
--
--@param target_folder Folder where the image will be saved to
--@param file_name Name of the file to be written on disk
local save_clipboard_to = function(target_folder, file_name)
    -- Copy image from clipboard
    local clip_command = 'osascript' ..
            ' -e "tell application \\"System Events\\" to' ..
            ' write (the clipboard as «class PNGf») to' ..
            ' (make new file at folder \\"' .. target_folder .. '\\"' ..
            ' with properties {name:\\"'.. file_name .. '\\"})"'

    os.execute(clip_command)
end

-- Write text in the current buffer
--
--@param text Text to be written in the current buffer
local write_text = function(text)
    local pos = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line()
    local nline = line:sub(0, pos) .. text .. line:sub(pos + 1)
    vim.api.nvim_set_current_line(nline)
end

--- Function equivalent to basename in POSIX systems
--
--@param path The path string
local basename = function(path)
    local name = string.gsub(path, "(.*/)(.*)", "%2")
    return name
end

--- Main incolla.nvim function
M.incolla = function()
    if not is_mac_os() then
        vim.notify("[Incolla]: Unsupported OS", vim.log.levels.ERROR)
        return
    end

    local clip = get_clipboard_info()
    if clip.Type == Content.UNSUPPORTED then
        vim.notify("[Incolla]: Unsupported clipboard content", vim.log.levels.WARN)
        return
    end

    local buf = vim.api.nvim_win_get_buf(0)
    if vim.bo[buf].readonly then
        vim.notify("[Incolla]: Buffer is readonly", vim.log.levels.WARN)
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
        vim.notify("[Incolla]: Copy from clipboard")
        file_name = os.date("IMG-%d-%m-%Y-%H-%M-%S.png")
        save_clipboard_to(target_folder_full_path, file_name)
    elseif clip.Type == Content.FURL then
        -- Copy file to destination
        vim.notify("[Incolla]: Copy from file url")
        local uv = vim.loop
        file_name = basename(clip.Path)
        assert(uv.fs_copyfile(clip.Path, target_folder_full_path .. "/" .. file_name))
    end

    -- Add text at current position using relative path
    local text = string.format("![%s](%s/%s)", file_name, target_folder_rel_path, file_name)
    write_text(text)
end

return M
