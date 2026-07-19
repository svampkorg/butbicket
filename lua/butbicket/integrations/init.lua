-- Integration registry.
--
-- Each entry is a plugin butbicket themes. `set_groups` merges an integration's
-- highlights only when it is BOTH enabled in `config.integrations` AND actually
-- installed (auto-detect). This keeps `nvim_get_hl(0, {})` uncluttered and
-- matches the mini.hues gating model.
--
-- Adding an integration: create `integrations/<module>.lua` with an
-- `M.highlights()` (or `M.highlights(config)` when `config = true`), then add a
-- row here. The reload list in `init.lua` is derived from this registry, so a
-- new module can never drift out of the palette-reload set.

local M = {}

---@class butbicket.IntegrationSpec
---@field name string config key in `config.integrations`
---@field module string module under `butbicket.integrations.`
---@field detect string|string[]|fun():boolean module name(s) whose presence
---       means "installed", or a predicate (for vimscript plugins with no
---       requireable module, e.g. `vim.g.loaded_*`)
---@field wants_config? boolean pass the resolved config to `highlights()`
---@field standalone? boolean not merged into `set_groups` (applied elsewhere),
---       but still reloaded

---@type butbicket.IntegrationSpec[]
M.registry = {
  { name = "cmp", module = "cmp", detect = "cmp" },
  { name = "neogit", module = "neogit", detect = "neogit" },
  { name = "haunt", module = "haunt", detect = "haunt" },
  { name = "blink", module = "blink", detect = "blink.cmp" },
  { name = "snacks_indent", module = "snacks_indent", detect = "snacks" },
  { name = "flash", module = "flash", detect = "flash" },
  { name = "arrow", module = "arrow", detect = "arrow" },
  { name = "telescope", module = "telescope", detect = "telescope" },
  { name = "nvim_tree", module = "nvim_tree", detect = "nvim-tree" },
  { name = "diffview", module = "diffview", detect = "diffview" },
  { name = "which_key", module = "which_key", detect = "which-key" },
  {
    name = "todo_comments",
    module = "todo_comments",
    detect = "todo-comments",
  },
  { name = "snacks_picker", module = "snacks_picker", detect = "snacks" },
  { name = "neo_tree", module = "neo_tree", detect = "neo-tree" },
  {
    name = "treesitter_context",
    module = "treesitter_context",
    detect = "treesitter-context",
  },
  { name = "lazy", module = "lazy", detect = "lazy" },
  { name = "gitsigns", module = "gitsigns", detect = "gitsigns" },
  { name = "dap", module = "dap", detect = "dap" },
  { name = "grug_far", module = "grug_far", detect = "grug-far" },
  {
    name = "codecompanion",
    module = "codecompanion",
    detect = "codecompanion",
  },
  {
    name = "fugitive",
    module = "fugitive",
    detect = function()
      return vim.fn.exists("*FugitiveGitDir") == 1
    end,
  },
  {
    name = "matchup",
    module = "matchup",
    detect = function()
      return vim.g.loaded_matchup ~= nil
    end,
  },
  {
    name = "mini",
    module = "mini",
    detect = {
      "mini.nvim",
      "mini.files",
      "mini.pick",
      "mini.icons",
      "mini.statusline",
      "mini.indentscope",
      "mini.notify",
      "mini.hipatterns",
    },
  },
  {
    name = "render_markdown",
    module = "render_markdown",
    detect = { "render-markdown", "render_markdown" },
  },
  -- bufferline is consumed through its own `highlights` option (see
  -- `theme.setup` -> `theme.bufferline`), not `nvim_set_hl`, so it is applied
  -- standalone but still driven by this registry for detection + reload.
  {
    name = "bufferline",
    module = "bufferline",
    detect = "bufferline",
    wants_config = true,
    standalone = true,
  },
}

---True when the detect predicate passes, or at least one of `detect`'s modules
---is loaded or requireable.
---@param detect string|string[]|fun():boolean
---@return boolean
local function detectable(detect)
  if type(detect) == "function" then
    return detect() and true or false
  end
  local mods = type(detect) == "table" and detect or { detect }
  for _, mod in ipairs(mods) do
    if package.loaded[mod] ~= nil then
      return true
    end
    if pcall(require, mod) then
      return true
    end
  end
  return false
end

---Resolve the enable/disable state for `name` from `config.integrations`,
---falling back to `default` (itself defaulting to `true`).
---@param integrations butbicket.Integrations
---@param name string
---@return boolean
local function enabled(integrations, name)
  local value = integrations[name]
  if value == nil then
    value = integrations.default
  end
  if value == nil then
    return true
  end
  return value and true or false
end

---An integration contributes its groups only when enabled AND installed.
---@param spec butbicket.IntegrationSpec
---@param config butbicket.Config
---@return boolean
function M.has(spec, config)
  return enabled(config.integrations, spec.name) and detectable(spec.detect)
end

---Merged highlight groups from every enabled + installed, non-standalone
---integration.
---@param config butbicket.Config
---@return table
function M.highlights(config)
  local groups = {}
  for _, spec in ipairs(M.registry) do
    if not spec.standalone and M.has(spec, config) then
      local mod = require("butbicket.integrations." .. spec.module)
      local hl = spec.wants_config and mod.highlights(config)
        or mod.highlights()
      groups = vim.tbl_extend("force", groups, hl)
    end
  end
  return groups
end

---Every integration module's `require` path — the single source of truth for
---the palette-reload list in `init.lua`.
---@return string[]
function M.modules()
  local list = {}
  for _, spec in ipairs(M.registry) do
    list[#list + 1] = "butbicket.integrations." .. spec.module
  end
  return list
end

return M
