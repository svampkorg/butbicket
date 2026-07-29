-- Terminal / ANSI palette mapping: the single source of truth for which palette
-- key drives each terminal-emulator color. Consumed by:
--   * init.lua `set_terminal_colors` -> vim.g.terminal_color_* (Neovim :terminal)
--   * extras/init.lua `collect` -> the emitted terminal theme files
--   * the flavour playground preview column
-- so the playground preview always matches what `:ButbicketExtras` writes, and
-- both track the active flavour (they read the resolved, post-flavour palette).
--
-- Pure: takes a palette table, no requires, no side effects.

local M = {}

-- ANSI slots 0..15 -> palette key. Index IS the slot number.
M.ANSI = {
  [0] = "editorBackground",
  [1] = "syntaxError",
  [2] = "successText",
  [3] = "accentEmphasis",
  [4] = "syntaxFunction",
  [5] = "syntaxKeyword",
  [6] = "linkText",
  [7] = "mainText",
  [8] = "inactiveText",
  [9] = "errorText",
  [10] = "stringText",
  [11] = "warningText",
  [12] = "syntaxOperator",
  [13] = "specialKeyword",
  [14] = "stringText",
  [15] = "commentText",
}

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

---Resolve the terminal palette from a colorscheme table.
---@param c table<string, any> the resolved (post-flavour) palette
---@return { ansi: table<integer,string>, bg: string, fg: string, cursor: string, sel_bg: string, sel_fg: string, accent: string }
function M.spec(c)
  local ansi = {}
  for i = 0, 15 do
    ansi[i] = c[M.ANSI[i]]
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
