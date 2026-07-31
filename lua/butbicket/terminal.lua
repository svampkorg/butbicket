-- Terminal / ANSI palette mapping: the single source of truth for which palette
-- key drives each terminal-emulator color. Consumed by:
--   * init.lua `set_terminal_colors` -> vim.g.terminal_color_* (Neovim :terminal)
--   * extras/init.lua `collect` -> the emitted terminal theme files
--   * the flavour playground terminal preview
-- so the playground preview always matches what `:ButbicketExtras` writes, and
-- both track the active flavour (they read the resolved, post-flavour palette).
--
-- The 8 normal ANSI slots (0-7) come straight from palette keys. The 8 bright
-- slots (8-15) are DERIVED from them — each is its 0-7 counterpart nudged in
-- OKLCh (lightness delta + chroma multiplier) — so bright N is a true brighter/
-- more-saturated shade of normal N, per the terminal convention. The delta is
-- per-polarity (a light background wants "brighter" to mean more saturated, not
-- lighter) and flavour-tunable via `ansi_bright_l` / `ansi_bright_c`.
--
-- Pure apart from the leaf `oklab` module (also pure); no side effects.

local oklab = require("butbicket.oklab")

local M = {}

local HEX = "^#%x%x%x%x%x%x$"

-- Normal ANSI slots 0..7 -> palette key. Bright slots 8..15 are derived (below).
M.ANSI = {
  [0] = "editorBackground",
  [1] = "syntaxError",
  [2] = "successText",
  [3] = "accentEmphasis",
  [4] = "syntaxFunction",
  [5] = "syntaxKeyword",
  [6] = "linkText",
  [7] = "mainText",
}

-- Per-polarity defaults for the bright-slot derivation: `l` is an OKLCh lightness
-- delta (0-100 scale), `c` a chroma multiplier. Dark wants brighter = lighter +
-- a little more saturated; light wants brighter = more saturated and slightly
-- darker (lighter would wash out on a white background). A flavour overrides
-- these with `ansi_bright_l` / `ansi_bright_c`.
M.BRIGHT_DEFAULT = {
  dark = { l = 12, c = 1.1 },
  light = { l = -6, c = 1.18 },
}

---Resolve the bright-derivation deltas for a polarity, honoring flavour overrides.
---@param polarity string "dark" | "light"
---@param opts? { ansi_bright_l?: number, ansi_bright_c?: number }
---@return number l_delta, number c_mult
function M.bright_deltas(polarity, opts)
  local d = M.BRIGHT_DEFAULT[polarity] or M.BRIGHT_DEFAULT.dark
  opts = opts or {}
  local l = opts.ansi_bright_l
  local c = opts.ansi_bright_c
  return (l == nil) and d.l or l, (c == nil) and d.c or c
end

-- Derive a bright shade from a normal color: OKLCh lightness += l_delta (clamped)
-- and chroma *= c_mult. Non-hex values pass through unchanged.
local function bright(hex, l_delta, c_mult)
  if type(hex) ~= "string" or not hex:match(HEX) then
    return hex
  end
  local lch = oklab.hex_to_oklch(hex)
  lch.l = math.min(math.max(lch.l + l_delta, 0), 100)
  lch.c = lch.c * c_mult
  return oklab.oklch_to_hex(lch)
end

-- Non-ANSI terminal colors -> palette key. `foreground` (and the cursor, which
-- follows it) is the emphasis foreground, i.e. the "foreground" knob in the
-- flavour dialog — not the dimmer body text `mainText` it used to read. Selection
-- has its own bg + fg keys so both are independently tunable as flavour roles.
M.SPECIAL = {
  background = "editorBackground",
  foreground = "emphasisText",
  cursor = "emphasisText",
  selection_background = "selected",
  selection_foreground = "selectionText",
  accent = "linkText",
}

---Resolve the terminal palette from a colorscheme table. Slots 0-7 are read from
---the palette; 8-15 are derived brights. The bright deltas are read from
---`c.ansiBrightL` / `c.ansiBrightC` (stamped by colorscheme.lua / the playground),
---falling back to the dark defaults if absent.
---@param c table<string, any> the resolved (post-flavour) palette
---@return { ansi: table<integer,string>, bg: string, fg: string, cursor: string, sel_bg: string, sel_fg: string, accent: string }
function M.spec(c)
  local l_d = c.ansiBrightL or M.BRIGHT_DEFAULT.dark.l
  local c_m = c.ansiBrightC or M.BRIGHT_DEFAULT.dark.c
  local ansi = {}
  for i = 0, 7 do
    ansi[i] = c[M.ANSI[i]]
  end
  for i = 8, 15 do
    ansi[i] = bright(ansi[i - 8], l_d, c_m)
  end
  return {
    ansi = ansi,
    bg = c[M.SPECIAL.background],
    fg = c[M.SPECIAL.foreground],
    cursor = c[M.SPECIAL.cursor],
    sel_bg = c[M.SPECIAL.selection_background],
    sel_fg = c[M.SPECIAL.selection_foreground],
    accent = c[M.SPECIAL.accent],
  }
end

return M
