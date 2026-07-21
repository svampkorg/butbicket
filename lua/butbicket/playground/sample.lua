-- Static playground data: the knob model and the example-buffer content.
-- No logic beyond building the knob list from flavour's role tables, so the knob
-- order and role families can never drift from the generator.

local flavour = require("butbicket.flavour")

local M = {}

-- Accent-role order comes straight from flavour, so the knob list and serialize
-- output can never drift from the roles the generator actually supports.
M.ACCENT_ROLES = flavour.ROLE_ORDER

-- Locked roles split into two display families: the diff identities and the
-- diagnostic/status identities. Everything else is a normal accent (or a bg role).
M.DIFF_ROLES = { added = true, changed = true, removed = true }
M.DIAG_ROLES = {
  error = true,
  warn = true,
  info = true,
  hint = true,
  success = true,
}

-- Knob table. `neutral` is the value assumed when a numeric knob is unset and
-- the user starts nudging it. Accent knobs read/write `opts.accents[name]`.
M.KNOBS = {
  { name = "background", label = "background", kind = "hex", step = 2 },
  { name = "foreground", label = "foreground", kind = "hex", step = 2 },
  {
    name = "hue_shift",
    label = "hue_shift",
    kind = "deg",
    step = 5,
    neutral = 0,
  },
  {
    name = "chroma_mult",
    label = "chroma_mult",
    kind = "num",
    step = 0.05,
    min = 0,
    neutral = 1,
  },
  {
    name = "n_hues",
    label = "n_hues",
    kind = "int",
    step = 1,
    min = 0,
    neutral = 0,
  },
  {
    name = "base_hue",
    label = "base_hue",
    kind = "deg",
    step = 5,
    neutral = 0,
  },
}
for _, role in ipairs(M.ACCENT_ROLES) do
  local surface = flavour.ROLE_SURFACE[role]
  local locked = flavour.ROLE_LOCKED[role]
  local prefix
  if locked then
    prefix = M.DIFF_ROLES[role] and "diff." or "diag."
  elseif surface == "bg" then
    prefix = "ui."
  else
    prefix = "accent."
  end
  M.KNOBS[#M.KNOBS + 1] = {
    name = role,
    label = prefix .. role,
    kind = "accent",
    step = 5,
    surface = surface, -- "fg" (solid swatch) or "bg" (text-on-color swatch)
    locked = locked, -- diff identities: frozen from the hue wheel until pinned
  }
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
