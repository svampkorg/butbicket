# ButBicket

A Neovim colorscheme inspired by the [Bitbucket](https://bitbucket.org) code-review
palette — the colors you stare at for hours reviewing pull requests, now in your
editor. Ships **dark** and **light** variants and integrates with a handful of
popular plugins.

![preview](assets/sample-preview.png)

## Requirements

- Neovim >= 0.8
- `termguicolors` enabled (the colorscheme sets this for you)

## Installation

### lazy.nvim

```lua
{
  'svampkorg/butbicket',
  lazy = false,
  priority = 1000,
  config = function()
    require('butbicket').setup {} -- optional; see Configuration
    vim.cmd.colorscheme 'butbicket'
  end,
}
```

### packer.nvim

```lua
use {
  'svampkorg/butbicket',
  config = function()
    require('butbicket').setup {}
    vim.cmd.colorscheme 'butbicket'
  end,
}
```

## Usage

Pick a variant by setting the background before applying the colorscheme:

```lua
vim.o.background = 'dark' -- or 'light'
vim.cmd.colorscheme 'butbicket'
```

There are also explicit variant entrypoints:

```vim
colorscheme butbicket-dark
colorscheme butbicket-light
```

## Configuration

`setup {}` is optional. Defaults:

```lua
require('butbicket').setup {
  transparent = false, -- use the terminal background instead of a solid color
  italics = {
    comments = true,
    keywords = true,
    functions = false,
    strings = false,
    variables = false,
    variable_members = false,
    variable_parameters = true,
    statements = true,
    bufferline = false,
  },
  overrides = {}, -- table, or a function returning a table, of highlight groups
}
```

### Overriding highlights

```lua
require('butbicket').setup {
  overrides = {
    Comment = { fg = '#808080', italic = false },
    ['@variable'] = { fg = '#c0c0c0' },
  },
}
```

## Integrations

Highlight support ships for: nvim-cmp, blink.cmp, neogit, flash.nvim, arrow.nvim,
bufferline, snacks indent, haunt, render-markdown, and lualine.

For lualine:

```lua
require('lualine').setup { options = { theme = 'butbicket' } }
```

## Terminal colors

The scheme exports a 16-color palette to `vim.g.terminal_color_*`. Matching
terminal themes are generated from that same palette and committed under
`extras/`, one directory per terminal:

```
extras/ghostty/    extras/kitty/    extras/alacritty/    extras/wezterm/    extras/warp/
```

Regenerate them all (or a subset):

```sh
nvim -l scripts/gen-terminals.lua              # all terminals, both variants
nvim -l scripts/gen-terminals.lua dark         # both terminals, dark only
nvim -l scripts/gen-terminals.lua dark kitty   # dark, kitty only
```

Then point your terminal at the relevant file, e.g.:

- **Ghostty**: `theme = /path/to/extras/ghostty/butbicket-dark`
- **Kitty**: `include /path/to/extras/kitty/butbicket-dark.conf`
- **Alacritty**: `[general] import = ["/path/to/extras/alacritty/butbicket-dark.toml"]`
- **WezTerm**: copy into `~/.config/wezterm/colors/` and `config.color_scheme = 'butbicket-dark'`
- **Warp**: copy into `~/.warp/themes/`

Note: the ANSI slot mapping is aesthetic (chosen to look right in a shell), not a
literal red/green/blue mapping — e.g. slot 4 carries a mint tone. It mirrors
`set_terminal_colors()` in `lua/butbicket/init.lua`, so `:terminal` inside Neovim
and your host terminal stay in sync.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). In short: run `stylua .` and `nvim -l
tests/run.lua` before opening a PR.

## License

[MIT](LICENSE)
