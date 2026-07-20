local colorscheme = require("butbicket.colorscheme")
local oklab = require("butbicket.oklab")

local M = {}

local HEX = "^#%x%x%x%x%x%x$"

-- Flash is search on steroids, so its colors track the accent: FlashMatch uses
-- `hotpink` (the accent.accent flavour role), and the jump-label / current-match
-- foreground is derived from that same hotpink here. `colorscheme` is the graded
-- palette at this point, so an accent.accent pin flows straight through.
--
-- The label is the key you press to jump, so it must be eye-catchable whatever
-- hue the accent is tuned to: keep hotpink's hue but force high chroma and a
-- lightness that stands well off the editor background (bright on a dark bg,
-- deep on a light bg). This replaces the old fixed `bright_green`.
local function label_color()
  local hp = colorscheme.hotpink
  if type(hp) ~= "string" or not hp:match(HEX) then
    return hp
  end
  local lch = oklab.hex_to_oklch(hp)
  local bg = colorscheme.editorBackground
  local bg_l = (type(bg) == "string" and bg:match(HEX)) and oklab.lightness(bg)
    or 0
  -- Chroma peaks near the accent's own lightness and collapses toward white,
  -- so "bright" stays moderate to stay vivid rather than washing to pastel.
  return oklab.oklch_to_hex({
    l = bg_l < 50 and 68 or 45, -- lift off a dark bg, deepen against a light one
    c = math.max(lch.c, 30), -- vivid; gamut-clipped on convert
    h = lch.h or 0,
  })
end

function M.highlights()
  local label = label_color()
  return {
    FlashMatch = { fg = colorscheme.hotpink },
    FlashCurrent = {
      fg = label,
      bg = colorscheme.searchBase,
    },
    FlashLabel = { fg = label },
  }
end

return M
