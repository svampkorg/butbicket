-- Preview OKLab-derived light syntax colors against the current hand-tuned ones.
--
-- Usage:
--   nvim -l scripts/derive-light.lua
--
-- For each syntax foreground it takes the DARK palette value, inverts its
-- perceptual lightness (OKLab: L -> 100 - L), keeps hue + chroma (gamut-clipped),
-- then darkens until it clears the WCAG floor on white. Prints dark source,
-- current light hex, derived candidate, and both contrast ratios so the palette
-- author can decide which derived values to adopt. It does NOT modify anything.

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local oklab = require("butbicket.oklab")
local contrast = dofile("tests/contrast.lua")

local WHITE = "#ffffff"

-- Load one variant's palette in isolation.
local function palette(background)
  vim.o.background = background
  package.loaded["butbicket.colorscheme"] = nil
  package.loaded["butbicket.config"] = nil
  return require("butbicket.colorscheme")
end

-- Syntax foregrounds to grade, with their WCAG floor on the editor background
-- (mirrors tests/run.lua) and a target light-mode lightness `l` (OKLab, [0;100]).
-- Body text sits darker, comments lighter, syntax in a mid band; this beats a
-- naive L -> 100-L mirror, which over-darkens (L~75 dark fg -> L~25).
local targets = {
  { key = "mainText", floor = 4.5, l = 42 },
  { key = "commentText", floor = 2.5, l = 58 },
  { key = "stringText", floor = 3.0, l = 52 },
  { key = "syntaxKeyword", floor = 3.0, l = 50 },
  { key = "syntaxFunction", floor = 3.0, l = 50 },
  { key = "linkText", floor = 3.0, l = 50 },
  { key = "errorText", floor = 3.0, l = 52 },
  { key = "warningText", floor = 3.0, l = 52 },
  { key = "successText", floor = 3.0, l = 50 },
  { key = "specialKeyword", floor = 3.0, l = 48 },
  { key = "type", floor = 3.0, l = 46 },
  { key = "method", floor = 3.0, l = 48 },
  { key = "keyword", floor = 3.0, l = 50 },
  { key = "number", floor = 3.0, l = 48 },
  { key = "variable", floor = 3.0, l = 44 },
  { key = "parameter", floor = 3.0, l = 46 },
}

-- Set a target lightness, keep hue + chroma (gamut-clipped), then darken in
-- small steps until the WCAG floor on white is met.
local function derive(dark_hex, floor, target_l)
  local lch = oklab.hex_to_oklch(dark_hex)
  local l = target_l
  local cand = oklab.oklch_to_hex({ l = l, c = lch.c, h = lch.h })
  while contrast.ratio(cand, WHITE) < floor and l > 2 do
    l = l - 2
    cand = oklab.oklch_to_hex({ l = l, c = lch.c, h = lch.h })
  end
  return cand
end

local dark = palette("dark")
local light = palette("light")

print(
  string.format(
    "%-15s %-9s %-9s %-9s %7s %7s",
    "key",
    "dark",
    "current",
    "derived",
    "cur→AA",
    "der→AA"
  )
)
print(string.rep("-", 62))

for _, t in ipairs(targets) do
  local d = dark[t.key]
  local cur = light[t.key]
  if d and cur then
    local der = derive(d, t.floor, t.l)
    print(
      string.format(
        "%-15s %-9s %-9s %-9s %6.2f %6.2f",
        t.key,
        d,
        cur,
        der,
        contrast.ratio(cur, WHITE),
        contrast.ratio(der, WHITE)
      )
    )
  end
end
