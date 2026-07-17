-- WCAG 2.x relative-luminance contrast helpers.
-- Pure Lua, no Neovim API — usable from tests and from palette tooling.
local M = {}

local function hex_to_rgb(hex)
  hex = hex:gsub('#', '')
  return tonumber(hex:sub(1, 2), 16),
    tonumber(hex:sub(3, 4), 16),
    tonumber(hex:sub(5, 6), 16)
end

local function channel(c)
  c = c / 255
  if c <= 0.03928 then
    return c / 12.92
  end
  return ((c + 0.055) / 1.055) ^ 2.4
end

-- Relative luminance of a "#rrggbb" color, per WCAG.
function M.luminance(hex)
  local r, g, b = hex_to_rgb(hex)
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
end

-- Contrast ratio between two "#rrggbb" colors (1.0 .. 21.0).
function M.ratio(fg, bg)
  local l1 = M.luminance(fg)
  local l2 = M.luminance(bg)
  local lighter = math.max(l1, l2)
  local darker = math.min(l1, l2)
  return (lighter + 0.05) / (darker + 0.05)
end

return M
