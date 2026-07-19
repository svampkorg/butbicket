local config = require("butbicket.config")
local theme = {}

-- Modules whose output depends on `vim.o.background` / config and therefore
-- must be re-evaluated on every `colorscheme()` call (e.g. dark <-> light
-- toggle in the same session). `config` is intentionally excluded: it holds
-- user setup state via its metatable and must survive reloads.
local reloadable = {
  "butbicket.colorscheme",
  "butbicket.hl-groups",
  -- "butbicket.integrations.arrow",
  "butbicket.integrations.blink",
  "butbicket.integrations.bufferline",
  "butbicket.integrations.cmp",
  "butbicket.integrations.flash",
  "butbicket.integrations.haunt",
  "butbicket.integrations.neogit",
  "butbicket.integrations.snacks_indent",
}

local function reload()
  for _, module in ipairs(reloadable) do
    package.loaded[module] = nil
  end
end

local function set_terminal_colors()
  local colorscheme = require("butbicket.colorscheme")
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
  vim.g.terminal_color_13 = colorscheme.specialKeyword
  vim.g.terminal_color_14 = colorscheme.stringText
  vim.g.terminal_color_15 = colorscheme.commentText
  vim.g.terminal_color_background = colorscheme.editorBackground
  vim.g.terminal_color_foreground = colorscheme.mainText
end

local function set_groups()
  local groups = require("butbicket.hl-groups")

  -- integrations
  for _, name in ipairs({
    "cmp",
    "neogit",
    "haunt",
    "blink",
    "snacks_indent",
    "flash",
    "arrow",
  }) do
    groups = vim.tbl_extend(
      "force",
      groups,
      require("butbicket.integrations." .. name).highlights()
    )
  end

  -- overrides
  groups = vim.tbl_extend(
    "force",
    groups,
    type(config.overrides) == "function" and config.overrides()
      or config.overrides
  )

  for group, parameters in pairs(groups) do
    vim.api.nvim_set_hl(0, group, parameters)
  end
end

function theme.setup(values)
  values = values or {}
  setmetatable(
    config,
    { __index = vim.tbl_extend("force", config.defaults, values) }
  )

  local bufferline = require("butbicket.integrations.bufferline")
  theme.bufferline = { highlights = bufferline.highlights(config) }
end

function theme.colorscheme()
  if vim.fn.has("nvim-0.8") == 0 then
    vim.notify(
      "Neovim 0.8+ is required for butbicket colorscheme",
      vim.log.levels.ERROR,
      { title = "butbicket" }
    )
    return
  end

  vim.api.nvim_command("hi clear")
  if vim.fn.exists("syntax_on") then
    vim.api.nvim_command("syntax reset")
  end

  reload()

  vim.g.VM_theme_set_by_colorscheme = true
  vim.o.termguicolors = true
  vim.g.colors_name = "butbicket"

  set_terminal_colors()
  set_groups()
end

return theme
