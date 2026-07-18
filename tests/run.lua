-- Standalone test runner for the butbicket colorscheme.
-- Run with:  nvim -l tests/run.lua
-- No external dependencies (no plenary/busted); uses only the Neovim Lua API.
-- Exits non-zero on any failure so CI can gate on it.

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
local contrast = dofile("tests/contrast.lua")

local failures = {}
local function check(ok, msg)
  if ok then
    print("  ok   - " .. msg)
  else
    print("  FAIL - " .. msg)
    table.insert(failures, msg)
  end
end

-- Fresh palette for the current `vim.o.background`.
local function palette()
  package.loaded["butbicket.colorscheme"] = nil
  return require("butbicket.colorscheme")
end

-- Palette keys every highlight relies on. If any is nil, groups silently lose
-- their color (this is exactly the class of bug find-replace corruption causes).
local required_keys = {
  "editorBackground",
  "mainText",
  "emphasisText",
  "commentText",
  "lineNumberText",
  "syntaxFunction",
  "syntaxKeyword",
  "syntaxError",
  "syntaxOperator",
  "syntaxNumber",
  "stringText",
  "linkText",
  "errorText",
  "warningText",
  "successText",
  "specialKeyword",
  "windowBorder",
  "floatBorder",
}

-- fg-on-bg pairs to grade. Comments are intentionally low-contrast, so they get
-- a gentler floor. Everything else is body-legible syntax.
local function contrast_pairs(c)
  return {
    { name = "mainText", fg = c.mainText, floor = 4.5 },
    { name = "commentText", fg = c.commentText, floor = 2.5 },
    { name = "stringText", fg = c.stringText, floor = 3.0 },
    { name = "syntaxKeyword", fg = c.syntaxKeyword, floor = 3.0 },
    { name = "syntaxFunction", fg = c.syntaxFunction, floor = 3.0 },
    { name = "linkText", fg = c.linkText, floor = 3.0 },
    { name = "errorText", fg = c.errorText, floor = 3.0 },
    { name = "warningText", fg = c.warningText, floor = 3.0 },
    { name = "successText", fg = c.successText, floor = 3.0 },
    -- raw palette keys used directly as foreground by hl-groups.lua
    { name = "type", fg = c.type, floor = 3.0 },
    { name = "method", fg = c.method, floor = 3.0 },
    { name = "keyword", fg = c.keyword, floor = 3.0 },
    { name = "number", fg = c.number, floor = 3.0 },
    { name = "variable", fg = c.variable, floor = 3.0 },
    { name = "parameter", fg = c.parameter, floor = 3.0 },
    { name = "text_dark", fg = c.text_dark, floor = 4.5 },
  }
end

for _, bg in ipairs({ "dark", "light" }) do
  print("\n== background=" .. bg .. " ==")
  vim.o.background = bg

  -- 1. loads without error
  local ok, err = pcall(function()
    require("butbicket").colorscheme()
  end)
  check(ok, "colorscheme() loads (" .. bg .. ")")
  if not ok then
    print("       " .. tostring(err))
  end

  -- 2. no nil in required palette keys
  local c = palette()
  for _, key in ipairs(required_keys) do
    check(c[key] ~= nil, "palette." .. key .. " is defined")
  end

  -- 3. contrast grading against the editor background
  local editor_bg = c.editorBackground
  if editor_bg == "none" then
    editor_bg = bg == "light" and "#ffffff" or "#101214"
  end
  for _, pair in ipairs(contrast_pairs(c)) do
    if pair.fg then
      local r = contrast.ratio(pair.fg, editor_bg)
      check(
        r >= pair.floor,
        string.format(
          "%-16s %s on %s = %.2f (floor %.1f)",
          pair.name,
          pair.fg,
          editor_bg,
          r,
          pair.floor
        )
      )
    end
  end
end

print("")
if #failures > 0 then
  print(("%d check(s) failed"):format(#failures))
  os.exit(1)
end
print("all checks passed")
