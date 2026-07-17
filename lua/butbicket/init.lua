local arrow = require 'butbicket.integrations.arrow'
local blink = require 'butbicket.integrations.blink'
local bufferline = require 'butbicket.integrations.bufferline'
local cmp = require 'butbicket.integrations.cmp'
local flash = require 'butbicket.integrations.flash'
local haunt = require 'butbicket.integrations.haunt'
local neogit = require 'butbicket.integrations.neogit'
local snacks_indent = require 'butbicket.integrations.snacks_indent'
local config = require 'butbicket.config'
local colorscheme = require 'butbicket.colorscheme'
local theme = {}

local function set_terminal_colors()
  vim.g.terminal_color_0 = colorscheme.editorBackground
  vim.g.terminal_color_1 = colorscheme.syntaxError
  vim.g.terminal_color_2 = colorscheme.successText
  vim.g.terminal_color_3 = colorscheme.warningEmphasis
  vim.g.terminal_color_4 = colorscheme.syntaxFunction
  vim.g.terminal_color_5 = colorscheme.syntaxKeyword
  vim.g.terminal_color_6 = colorscheme.linkText
  vim.g.terminal_color_7 = colorscheme.mainText
  vim.g.terminal_color_8 = colorscheme.inactiveText
  vim.g.terminal_color_9 = colorscheme.errorText
  vim.g.terminal_color_10 = colorscheme.stringText
  vim.g.terminal_color_11 = colorscheme.warningText
  vim.g.terminal_color_12 = colorscheme.syntaxOperator
  vim.g.terminal_color_13 = colorscheme.syntaxError
  vim.g.terminal_color_14 = colorscheme.stringText
  vim.g.terminal_color_15 = colorscheme.commentText
  vim.g.terminal_color_background = colorscheme.editorBackground
  vim.g.terminal_color_foreground = colorscheme.mainText
end

local function set_groups()
  local groups = require('hl-groups')

  -- integrations
  groups = vim.tbl_extend('force', groups, cmp.highlights())
  groups = vim.tbl_extend('force', groups, neogit.highlights())
  groups = vim.tbl_extend('force', groups, haunt.highlights())
  groups = vim.tbl_extend('force', groups, blink.highlights())
  groups = vim.tbl_extend('force', groups, snacks_indent.highlights())
  groups = vim.tbl_extend('force', groups, flash.highlights())
  groups = vim.tbl_extend('force', groups, arrow.highlights())

  -- overrides
  groups = vim.tbl_extend(
    'force',
    groups,
    type(config.overrides) == 'function' and config.overrides()
      or config.overrides
  )

  for group, parameters in pairs(groups) do
    vim.api.nvim_set_hl(0, group, parameters)
  end
end

function theme.setup(values)
  setmetatable(
    config,
    { __index = vim.tbl_extend('force', config.defaults, values) }
  )

  theme.bufferline = { highlights = {} }
  theme.bufferline.highlights = bufferline.highlights(config)
end

function theme.colorscheme()
  if vim.version().minor < 8 then
    vim.notify(
      'Neovim 0.8+ is required for butbicket colorscheme',
      vim.log.levels.ERROR,
      { title = 'Min Theme' }
    )
    return
  end

  vim.api.nvim_command 'hi clear'
  if vim.fn.exists 'syntax_on' then
    vim.api.nvim_command 'syntax reset'
  end

  vim.g.VM_theme_set_by_colorscheme = true
  vim.o.termguicolors = true
  vim.g.colors_name = 'butbicket'

  set_terminal_colors()
  set_groups()
end

return theme
