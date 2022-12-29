-- Check nvim version
if 1 ~= vim.fn.has("nvim-0.7.0") then
    vim.api.nvim_err_writeln("Incolla.nvim requires at least nvim-0.7.0.")
    return
end

-- Check OS
if 1 ~= vim.fn.has("macunix") then
    vim.api.nvim_err_writeln("Incolla.nvim only supports MacOS")
    return
end

-- Prevent loading plugin twice
if vim.g.loaded_incolla == 1 then
  return
end
vim.g.loaded_incolla = 1

-- Create vim command
vim.api.nvim_create_user_command('Incolla',
    function()
        require'incolla'.incolla()
    end, {})
