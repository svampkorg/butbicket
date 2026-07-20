local colorscheme = require("butbicket.colorscheme")
local contrast = require("butbicket.contrast")
local oklab = require("butbicket.oklab")

local M = {}

local HEX = "^#%x%x%x%x%x%x$"

-- Flash is search on steroids, so its colors track the accent: FlashMatch uses
-- `hotpink` (the accent.accent flavour role), and both the current-match fg and
-- the jump label are derived from that same hotpink here. `colorscheme` is the
-- graded palette at this point, so an accent.accent pin flows straight through.

local function bg_is_dark()
  local bg = colorscheme.editorBackground
  local l = (type(bg) == "string" and bg:match(HEX)) and oklab.lightness(bg)
    or 0
  return l < 50
end

-- A bright, vivid foreground in the accent hue for the current match. Chroma
-- peaks near the accent's own lightness and collapses toward white, so "bright"
-- stays moderate to stay vivid rather than washing to pastel.
local function match_fg(lch, dark)
  return oklab.oklch_to_hex({
    l = dark and 68 or 45, -- lift off a dark bg, deepen against a light one
    c = math.max(lch.c, 30), -- vivid; gamut-clipped on convert
    h = lch.h or 0,
  })
end

-- The jump label as a filled "keycap": a solid chip in the COMPLEMENTARY hue
-- (accent + 180°) so it reads as a different color from the pink match around
-- it, with a near-black/white letter picked for max contrast. A fg-only label
-- gets lost among syntax; a chip pops. Bold on top.
local function label_chip(lch, dark)
  local chip = oklab.oklch_to_hex({
    l = dark and 60 or 52,
    c = math.max(lch.c, 34),
    h = ((lch.h or 0) + 180) % 360,
  })
  local black, white = "#0a0a0a", "#f5f5f5"
  local letter = contrast.ratio(white, chip) >= contrast.ratio(black, chip)
      and white
    or black
  return chip, letter
end

function M.highlights()
  local hp = colorscheme.hotpink
  if type(hp) ~= "string" or not hp:match(HEX) then
    -- Degenerate palette (e.g. transparent/odd flavour): fall back to the raw
    -- accent so flash still renders something sane.
    return {
      FlashMatch = { fg = hp },
      FlashCurrent = { fg = hp, bg = colorscheme.searchBase },
      FlashLabel = { fg = hp, bold = true },
    }
  end

  local lch = oklab.hex_to_oklch(hp)
  local dark = bg_is_dark()
  local chip, letter = label_chip(lch, dark)
  return {
    FlashMatch = { fg = hp },
    FlashCurrent = {
      fg = match_fg(lch, dark),
      bg = colorscheme.searchBase,
    },
    FlashLabel = { fg = letter, bg = chip, bold = true },
  }
end

return M
