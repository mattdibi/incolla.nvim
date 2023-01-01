local M = {}

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
    local clip_info = tostring(io.popen('osascript -e "clipboard info" 2>/dev/null'):read())
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

-- Clipboard content
M.Content = {
    IMAGE = "0",
    FURL  = "1",
    UNSUPPORTED = "2"
}

--- Get information about clipboard content
---@return table: Table containing the Content, Ext and Path
M.get_info = function()
    local reported_type = osascript_get_clip_content()

    if reported_type:find("PNGf") or reported_type:find("TIFF") then
        return { Type = M.Content.IMAGE, Path = "" , Ext = ".png"}
    end

    if reported_type:find("furl") then
        local clip_path = osascript_get_clip_path()

        if is_path_to_img(clip_path) then
            local extension = "." .. vim.fn.fnamemodify(clip_path, ":e")
            return { Type = M.Content.FURL, Path = clip_path, Ext = extension }
        end
    end

    return { Type = M.Content.UNSUPPORTED, Path = "", Ext = "" }
end

-- Save image from clipboard to disk
--
---@param dst_path string: Path where the image will be saved to
M.save_to = function(dst_path)
    local dst_dir  = vim.fn.fnamemodify(dst_path, ":p:h")
    local dst_name = vim.fn.fnamemodify(dst_path, ":t")

    -- Save image as PNG from clipboard to tmp_path
    local clip_command = 'osascript' ..
            ' -e "tell application \\"System Events\\" to' ..
            ' write (the clipboard as «class PNGf») to' ..
            ' (make new file at folder \\"' .. dst_dir .. '\\"' ..
            ' with properties {name:\\"'.. dst_name .. '\\"})"'

    os.execute(clip_command)
end

return M
