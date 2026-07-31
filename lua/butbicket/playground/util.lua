-- Shared primitives for the flavour playground: constants, small formatting /
-- validation helpers, the float builder, and the pure palette-grading readout.
-- Kept in a leaf module (no dependency on the other playground files) so panel,
-- serialize, and the color editor can all share it without a require cycle.

local flavour = require("butbicket.flavour")
local terminal = require("butbicket.terminal")

local M = {}

M.HEX = "^#%x%x%x%x%x%x$"
M.NS = vim.api.nvim_create_namespace("butbicket_flavour_playground")
M.SWATCH = "██" -- two full blocks; U+2588 is 3 bytes each
M.BG_SWATCH = "Ab" -- text on a background swatch, to preview fg/bg contrast
M.TERM_GLYPH = "" -- nf-fa-terminal (U+F120); marks roles that feed an ANSI slot

function M.clamp(x, lo, hi)
  return math.min(math.max(x, lo), hi)
end

function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "butbicket flavour" })
end

function M.is_hex(v)
  return type(v) == "string" and v:match(M.HEX) ~= nil
end

function M.fmt_num(x)
  if x == math.floor(x) then
    return tostring(math.floor(x))
  end
  return ("%.4g"):format(x)
end

function M.make_float(buf, opts)
  return vim.api.nvim_open_win(buf, opts.enter, {
    relative = "editor",
    row = opts.row,
    col = opts.col,
    width = opts.width,
    height = opts.height,
    style = "minimal",
    border = "rounded",
    title = opts.title,
    title_pos = "center",
  })
end

-- Build the flavoured palette purely (same transform colorscheme.lua applies),
-- so the panel can read the resulting role colors for its contrast readout. The
-- bright-ANSI deltas are stamped on (mirroring colorscheme.lua) so the terminal
-- preview derives slots 8-15 for the current polarity + any ansi_bright_l/_c.
function M.graded_palette(session)
  local p = flavour.generate_hues(session.base, session.opts)
  p.ansiBrightL, p.ansiBrightC =
    terminal.bright_deltas(session.polarity, session.opts)
  return p
end

return M
