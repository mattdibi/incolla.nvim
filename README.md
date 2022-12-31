<div align="center">

## incolla.nvim

![](https://img.shields.io/badge/MacOS-000000?style=flat-square&logo=apple&logoColor=white)
</br><a href="/LICENSE.md"> ![License](https://img.shields.io/badge/License-MIT-brightgreen?style=flat-square) </a>

_Neovim Lua plugin to paste images from MacOS clipboard_

</div>

### ✨ Features

- No dependencies
- Multiple image format supported (JPG, PNG ...)
- Easy extensibility and configuration
- Written entirely in Lua

### 📦 Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use 'mattdibi/incolla.nvim'
```

### 🚀 Usage

**Paste screenshot from clipboard**

![IncollaBasic](https://user-images.githubusercontent.com/22748355/210150002-135316ea-5574-443c-b71b-cc089784df7e.gif)

<details>
<summary><b>Paste image from clipboard URL</b></summary></br>

![IncollaURL](https://user-images.githubusercontent.com/22748355/210150024-41c94e32-d688-4e8a-bb68-c42c1c8fbf7b.gif)

</details>

<details>
<summary><b>Paste image copied from the browser</b></summary></br>

![IncollaBrowser](https://user-images.githubusercontent.com/22748355/210150032-376ead8a-ff21-433e-a9f0-7dec4ac58fd5.gif)

</details>

### ⚙️ Configuration

Incolla.nvim doesn't require any configuration to work out-of-the box. The default configuration is the following:

```lua
defaults = {
    img_dir = "imgs",
    img_name = function()
        return os.date("IMG-%d-%m-%Y-%H-%M-%S")
    end,
    affix = "%s",
}
```

Where:

- `img_dir`: Directory where the image from clipboard will be copied to
- `img_name`: Image's name on disk
- `affix`: String that sandwiches the image's path and will be written in your open buffer

If you want to customize the behaviour of the plugin you can look at the following section.

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
    -- Missing options from `<filetype>` field will be replaced by the default configuration
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

<details>
<summary><b>Vimscript</b></summary></br>

```vimscript
nnoremap <leader>xp :Incolla<CR>
```

</details>

### 🌟 Credits

Thanks to:
- [ekickx/clipboard-image.nvim](https://github.com/ekickx/clipboard-image.nvim)
- [img-paste-devs/img-paste.vim](https://github.com/img-paste-devs/img-paste.vim)
