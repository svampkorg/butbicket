local config = require("butbicket.config")
local theme = {}

-- Modules whose output depends on `vim.o.background` / config and therefore
-- must be re-evaluated on every `colorscheme()` call (e.g. dark <-> light
-- toggle in the same session). `config` is intentionally excluded: it holds
-- user setup state via its metatable and must survive reloads.
--
-- The integration module list is derived from the registry so it can never
-- drift out of sync with the integrations that are actually applied.
local function reload()
  local integrations = require("butbicket.integrations")
  local reloadable = {
    "butbicket.colorscheme",
    "butbicket.hl-groups",
    "butbicket.integrations",
  }
  vim.list_extend(reloadable, integrations.modules())
  for _, module in ipairs(reloadable) do
    package.loaded[module] = nil
  end
end

local function set_terminal_colors()
  -- The ANSI slots + terminal bg/fg mapping lives in butbicket.terminal, shared
  -- with the extras generator and the playground preview (single source of truth).
  local spec =
    require("butbicket.terminal").spec(require("butbicket.colorscheme"))
  for i = 0, 15 do
    vim.g["terminal_color_" .. i] = spec.ansi[i]
  end
  vim.g.terminal_color_background = spec.bg
  vim.g.terminal_color_foreground = spec.fg
end

local function set_groups()
  local groups = require("butbicket.hl-groups")

  -- integrations (enabled + installed only; see the registry)
  groups = vim.tbl_extend(
    "force",
    groups,
    require("butbicket.integrations").highlights(config)
  )

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

---Merge user options over the defaults (via the `config` metatable, so later
---`colorscheme()` reloads keep reading the live values) and rebuild the
---bufferline highlight table. Safe to call repeatedly.
---@param values? butbicket.Config user overrides (nil = defaults only)
function theme.setup(values)
  values = values or {}
  setmetatable(
    config,
    { __index = vim.tbl_extend("force", config.defaults, values) }
  )

  local bufferline = require("butbicket.integrations.bufferline")
  theme.bufferline = { highlights = bufferline.highlights(config) }
end

---Apply the colorscheme: clear existing highlights, reload the palette-dependent
---modules (so a `vim.o.background` toggle or config change takes effect), set the
---terminal ANSI colors, and define every highlight group. This is what
---`colors/butbicket.lua` calls.
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
