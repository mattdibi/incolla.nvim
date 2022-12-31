local M = {}

--- Check if directory at path exists, if not it creates one
---
---@param dir string: Path of the directory to check
M.create_dir = function(dir)
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end
end

--- Check if file at path exists
---
---@param path string: Path to be checked
M.file_exists = function(path)
   local f = io.open(path, "r")
   return f ~= nil and io.close(f)
end

return M
