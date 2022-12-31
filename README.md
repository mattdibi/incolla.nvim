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
    defaults = {
        img_dir = "imgs",
        img_name = function()
            return os.date('%Y-%m-%d-%H-%M-%S')
        end,
        affix = "![](%s)",
    }
}
```
