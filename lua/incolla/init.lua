local M = {}

local create_dir = function(dir)
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end
end

local determine_clipboard_content = function()
    local get_clip_info = 'osascript -e "clipboard info"'

    local outputs = io.popen(get_clip_info)

    local command_output = ""
    for output in outputs:lines() do
        command_output = command_output .. output
    end

    local first_type = command_output:match("[^,]+")

    if string.find(first_type, "PNGf") then
        print("PNG")
    elseif string.find(first_type, "TIFF") then
        print("TIFF")
    elseif string.find(first_type, "furl") then
        print("File url")
        local get_full_path = 'osascript -e "POSIX path of (the clipboard as «class furl»)"'

        local path_outputs = io.popen(get_full_path)

        local full_path = ""
        for output in path_outputs:lines() do
            full_path = full_path .. output
        end

        print(full_path)
    else
        print("Dunnolol")
    end
end


local write_file = function(target_folder, file_name)
    -- Copy image from clipboard
    local clip_command = 'osascript' ..
            ' -e "tell application \\"System Events\\" to' ..
            ' write (the clipboard as «class PNGf») to' ..
            ' (make new file at folder \\"' .. target_folder .. '\\"' ..
            ' with properties {name:\\"'.. file_name .. '\\"})"'

    --io.popen(clip_command)
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

--     determine_clipboard_content()

    -- Create directory if missing
    create_dir(target_folder_full_path)

    -- Write new file to disk
    write_file(target_folder_full_path, file_name)

    -- Add text at current position
    write_text(target_folder_rel_path, file_name)
end

return M
