local M = {}

-- Clipboard content
local Content = {
    IMAGE = "0",
    FURL  = "1",
    UNSUPPORTED = "2"
}

local create_dir = function(dir)
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end
end

local determine_clipboard_content = function()
    -- Retrieve clipboard info
    local clip_info_handle = io.popen('osascript -e "clipboard info"')
    local clip_info = clip_info_handle:read("*a")
    clip_info_handle:close()

    -- Retrieve header info
    local reported_type = clip_info:match("[^,]+")

    if string.find(reported_type, "PNGf") or string.find(reported_type, "TIFF") then
        return { Type = Content.IMAGE, Path = "" }
    elseif string.find(reported_type, "furl") then
        -- If clipboard type is file url, check it points to an actual image
        local clip_path_handle = io.popen('osascript -e "POSIX path of (the clipboard as «class furl»)"')
        local clip_path = clip_path_handle:read("*a")
        clip_path_handle:close()

        if string.find(clip_path, ".png")  or string.find(clip_path, ".jpg") or string.find(clip_path, ".jpeg") then
            return { Type = Content.FURL, Path = clip_path }
        else
            return { Type = Content.UNSUPPORTED, Path = "" }
        end
    else
        return { Type = Content.UNSUPPORTED, Path = "" }
    end
end


local write_file = function(target_folder, file_name)
    -- Copy image from clipboard
    local clip_command = 'osascript' ..
            ' -e "tell application \\"System Events\\" to' ..
            ' write (the clipboard as «class PNGf») to' ..
            ' (make new file at folder \\"' .. target_folder .. '\\"' ..
            ' with properties {name:\\"'.. file_name .. '\\"})"'

    os.execute(clip_command)
end

local write_text = function(target_folder, file_name)
    local pos = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line()

    local text = string.format("![%s](%s/%s)", file_name, target_folder, file_name)

    local nline = line:sub(0, pos) .. text .. line:sub(pos + 1)

    vim.api.nvim_set_current_line(nline)
end

M.incolla = function()
    local file_name = os.date("IMG-%d-%m-%Y-%H-%M-%S.png")

    local current_folder = vim.fn.expand('%:p:h')
    local imgdir = "imgs"

    local target_folder_full_path = current_folder .. "/" .. imgdir
    local target_folder_rel_path = "./" .. imgdir

    local clip = determine_clipboard_content()
    if clip.Type == Content.UNSUPPORTED then
        -- Do nothing
        return
    end

    -- Create directory if missing
    create_dir(target_folder_full_path)

    -- Write new file to disk
    if clip.Type == Content.IMAGE then
        write_file(target_folder_full_path, file_name)
    elseif clip.Type == Content.FURL then
        -- Copy file to destination
    end

    -- Add text at current position
    write_text(target_folder_rel_path, file_name)
end

return M
