<div align="center">

## incolla.nvim

![](https://img.shields.io/badge/MacOS-000000?style=flat-square&logo=apple&logoColor=white)
</br><a href="/LICENSE.md"> ![License](https://img.shields.io/badge/License-MIT-brightgreen?style=flat-square) </a>

_Neovim Lua plugin to paste images from MacOS clipboard_

</div>

### Features

- No dependencies
- Multiple image format supported (JPG, PNG ...)
- Easy extensibility and configuration
- Written entirely in Lua

### Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use 'mattdibi/incolla.nvim'
```

### Configuration

**Example**

In you Neovim configuration directory, create a new file inside the `after/plugin` directory with the following:

```lua
require("incolla").setup {
    -- Default configuration for all filetype
    defaults = {
        img_dir = "imgs",
        img_name = function()
            return os.date('%Y-%m-%d-%H-%M-%S')
        end,
        affix = "%s",
    },
    -- You can customize the behaviour for a filetype by creating a field named after the desired filetype
    -- If you're uncertain what to name your field to, you can run `lua print(vim.bo.filetype)`
    -- Missing options from `<filetype>` field will be replaced by the `DEFAULT` options
    markdown = {
        affix = "![](%s)",
    }
}
```

**Setting your keymap**

```lua
-- This maps the paste command to <leader>xp
vim.api.nvim_set_keymap('n', '<leader>xp', '', {
    noremap = true,
    callback = function()
        require'incolla'.incolla()
    end,
})
```

### Credits

Thanks to:
- [ekickx/clipboard-image.nvim](https://github.com/ekickx/clipboard-image.nvim)
- [img-paste-devs/img-paste.vim](https://github.com/img-paste-devs/img-paste.vim)
