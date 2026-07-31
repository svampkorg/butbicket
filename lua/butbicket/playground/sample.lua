-- Static playground data: the knob model and the example-buffer content.
-- No logic beyond building the knob list from flavour's role tables, so the knob
-- order and role families can never drift from the generator.

local flavour = require("butbicket.flavour")
local terminal = require("butbicket.terminal")

local M = {}

-- Accent-role order comes straight from flavour, so the knob list and serialize
-- output can never drift from the roles the generator actually supports.
M.ACCENT_ROLES = flavour.ROLE_ORDER

-- Locked roles that get a demo block in the sample float, so sync_example can
-- scroll them into view when focused: the diff identities and the diagnostics.
M.DIFF_ROLES = { added = true, changed = true, removed = true }
M.DIAG_ROLES = {
  error = true,
  warn = true,
  info = true,
  hint = true,
  success = true,
}

-- Which terminal ANSI slot(s) each role drives, for the knob indicator. Only the
-- 8 normal slots (0-7) map to a key; the bright slots (8-15) are DERIVED from
-- them (terminal.spec), so each normal role also drives slot i+8. A slot's key is
-- matched to its role directly or via the success derived alias (colorscheme.lua
-- sets successText = successBase post-flavour).
local ANSI_ALIAS = { successText = "success" }
local key_role = {}
for _, r in ipairs(flavour.ROLES) do
  for _, k in ipairs(r.keys) do
    key_role[k] = r.name
  end
end
M.ROLE_ANSI = {}
for i = 0, 7 do
  local role = key_role[terminal.ANSI[i]] or ANSI_ALIAS[terminal.ANSI[i]]
  if role then
    M.ROLE_ANSI[role] = M.ROLE_ANSI[role] or {}
    -- the role drives the normal slot i AND its derived bright slot i + 8
    table.insert(M.ROLE_ANSI[role], i)
    table.insert(M.ROLE_ANSI[role], i + 8)
  end
end

-- Knob table. `neutral` is the value assumed when a numeric knob is unset and
-- the user starts nudging it. Accent knobs read/write `opts.accents[name]`.
-- `group` places each knob under a playground section header; the global knobs
-- (bg/fg + the wheel controls) form the first section.
M.KNOBS = {
  {
    name = "background",
    label = "background",
    kind = "hex",
    step = 2,
    group = "global",
    ansi = { 0, 8 }, -- editorBackground = ANSI 0; bright-black (8) derives from it
  },
  {
    name = "foreground",
    label = "foreground",
    kind = "hex",
    step = 2,
    group = "global",
  },
  {
    name = "hue_shift",
    label = "hue_shift",
    kind = "deg",
    step = 5,
    neutral = 0,
    group = "global",
  },
  {
    name = "chroma_mult",
    label = "chroma_mult",
    kind = "num",
    step = 0.05,
    min = 0,
    neutral = 1,
    group = "global",
  },
  {
    name = "n_hues",
    label = "n_hues",
    kind = "int",
    step = 1,
    min = 0,
    neutral = 0,
    group = "global",
  },
  {
    name = "base_hue",
    label = "base_hue",
    kind = "deg",
    step = 5,
    neutral = 0,
    group = "global",
  },
  -- bright-ANSI derivation: slots 8-15 = normal 0-7 nudged by these (OKLCh
  -- lightness delta + chroma mult). Unset = the per-polarity default.
  {
    name = "ansi_bright_l",
    label = "ansi_bright_l",
    kind = "num",
    step = 2,
    neutral = 12,
    group = "global",
  },
  {
    name = "ansi_bright_c",
    label = "ansi_bright_c",
    kind = "num",
    step = 0.05,
    min = 0,
    neutral = 1.1,
    group = "global",
  },
}
for _, role in ipairs(M.ACCENT_ROLES) do
  M.KNOBS[#M.KNOBS + 1] = {
    name = role,
    label = role, -- section header carries the group; label is the plain role
    kind = "accent",
    step = 5,
    surface = flavour.ROLE_SURFACE[role], -- "fg" solid swatch / "bg" text-on-color
    locked = flavour.ROLE_LOCKED[role], -- frozen from the hue wheel until pinned
    group = flavour.ROLE_GROUP[role],
    ansi = M.ROLE_ANSI[role], -- terminal slot(s) this role feeds, or nil
  }
end

-- Section headers shown above the first knob of each group, in group order.
M.GROUP_LABELS = {
  global = "global",
  syntax = "syntax",
  ui = "ui · surfaces, borders, text",
  state = "search & selection",
  diff = "diff",
  diagnostic = "diagnostics",
}
M.GROUP_ORDER = { "global" }
for _, g in ipairs(flavour.GROUP_ORDER) do
  M.GROUP_ORDER[#M.GROUP_ORDER + 1] = g
end

M.SAMPLE = [[
-- flavour playground sample
local Animal = {}
Animal.__index = Animal

function Animal.new(name, legs)
  return setmetatable({ name = name, legs = legs or 4 }, Animal)
end

function Animal:describe()
  local kind = self.legs == 2 and "biped" or "quadruped"
  return string.format("%s is a %s (%d legs)", self.name, kind, self.legs)
end

local zoo = { Animal.new("cat"), Animal.new("stork", 2) }
for i = 1, #zoo do
  print(zoo[i]:describe()) -- TODO: sort by legs
end

if not zoo[1] then
  error("empty zoo!")
end
]]

-- A small git-diff demo appended to the sample so the diff.* roles (and the
-- derived line backgrounds) are visible in the float without a real git buffer
-- or a signs plugin. Each line gets a DiffAdd/Change/Delete line background and
-- a sign coloured by the Added/Changed/Removed foreground groups; all recolor
-- live with the flavour.
M.DIFF_DEMO = {
  {
    text = "  local inserted = true",
    line = "DiffAdd",
    sign = "+",
    sfg = "Added",
  },
  {
    text = '  local modified = "edit"',
    line = "DiffChange",
    sign = "~",
    sfg = "Changed",
  },
  {
    text = "  local deleted = nil",
    line = "DiffDelete",
    sign = "-",
    sfg = "Removed",
  },
}

-- A diagnostics demo, same idea as the diff demo: each line gets a
-- DiagnosticLine{Error,Warn,Info,Hint} background, a gutter sign coloured by the
-- matching Diagnostic{Error,Warn,Info,Hint} fg, and an eol virtual message in the
-- virtual-text group — so the error/warn/info/hint roles are all visible and
-- recolor live with the flavour.
M.DIAG_DEMO = {
  {
    text = "  danger()",
    line = "DiagnosticLineError",
    sign = "E",
    grp = "DiagnosticError",
    vt = "DiagnosticVirtualTextError",
    msg = "undefined global",
  },
  {
    text = "  shady()",
    line = "DiagnosticLineWarn",
    sign = "W",
    grp = "DiagnosticWarn",
    vt = "DiagnosticVirtualTextWarn",
    msg = "unused result",
  },
  {
    text = "  note()",
    line = "DiagnosticLineInfo",
    sign = "I",
    grp = "DiagnosticInfo",
    vt = "DiagnosticVirtualTextInfo",
    msg = "shadowed local",
  },
  {
    text = "  tip()",
    line = "DiagnosticLineHint",
    sign = "H",
    grp = "DiagnosticHint",
    vt = "DiagnosticVirtualTextHint",
    msg = "prefer :method()",
  },
}

return M
