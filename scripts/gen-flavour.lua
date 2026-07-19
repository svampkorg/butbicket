-- Preview generated flavours: re-tone the canonical dark palette onto new bases
-- and grade the syntax foregrounds for contrast against each flavour's own
-- background. Read-only; writes nothing.
--
-- Usage:  nvim -l scripts/gen-flavour.lua

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local flavour = require("butbicket.flavour")
local contrast = dofile("tests/contrast.lua")

vim.o.background = "dark"
package.loaded["butbicket.colorscheme"] = nil
local canonical = require("butbicket.colorscheme")

local flavours = {
  {
    name = "midnight (cool navy)",
    background = "#0d1b2a",
    foreground = "#e2e8f4",
    hue_shift = -8,
  },
  {
    name = "sepia (warm)",
    background = "#1c1714",
    foreground = "#ece0d2",
    hue_shift = 12,
    chroma_mult = 0.9,
  },
}

local syntax = {
  { key = "mainText", floor = 4.5 },
  { key = "commentText", floor = 2.5 },
  { key = "stringText", floor = 3.0 },
  { key = "syntaxKeyword", floor = 3.0 },
  { key = "syntaxFunction", floor = 3.0 },
  { key = "linkText", floor = 3.0 },
  { key = "errorText", floor = 3.0 },
  { key = "warningText", floor = 3.0 },
  { key = "successText", floor = 3.0 },
}

for _, f in ipairs(flavours) do
  local p = flavour.generate(canonical, f)
  print(
    string.format(
      "\n== %s  bg=%s fg=%s ==",
      f.name,
      p.editorBackground,
      p.mainText
    )
  )
  print(string.format("%-15s %-9s %7s  %s", "key", "hex", "vs bg", "floor"))
  print(string.rep("-", 44))
  local bg = p.editorBackground
  local fails = 0
  for _, s in ipairs(syntax) do
    local r = contrast.ratio(p[s.key], bg)
    local mark = r >= s.floor and "" or "  << FAIL"
    if r < s.floor then
      fails = fails + 1
    end
    print(
      string.format(
        "%-15s %-9s %6.2f   %.1f%s",
        s.key,
        p[s.key],
        r,
        s.floor,
        mark
      )
    )
  end
  print(
    fails == 0 and "  all syntax clears its floor"
      or ("  " .. fails .. " below floor")
  )
end
