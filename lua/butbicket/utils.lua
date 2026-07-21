local M = {}

local function hex_to_rgb(hex)
  local hex_type = "[abcdef0-9][abcdef0-9]"
  local pat = "^#(" .. hex_type .. ")(" .. hex_type .. ")(" .. hex_type .. ")$"
  hex = string.lower(hex)

  assert(
    string.find(hex, pat) ~= nil,
    "hex_to_rgb: invalid hex: " .. tostring(hex)
  )

  local red, green, blue = string.match(hex, pat)
  return { tonumber(red, 16), tonumber(green, 16), tonumber(blue, 16) }
end

---Alpha-blend two hex colors: `alpha` of `fg` over `(1 - alpha)` of `bg`.
---@param fg string foreground hex (`#rrggbb`)
---@param bg string background hex (`#rrggbb`)
---@param alpha number blend weight of `fg`, 0..1
---@return string mixed hex (`#RRGGBB`)
function M.mix(fg, bg, alpha)
  bg = hex_to_rgb(bg)
  fg = hex_to_rgb(fg)

  local blendChannel = function(i)
    local ret = (alpha * fg[i] + ((1 - alpha) * bg[i]))
    return math.floor(math.min(math.max(0, ret), 255) + 0.5)
  end

  return string.format(
    "#%02X%02X%02X",
    blendChannel(1),
    blendChannel(2),
    blendChannel(3)
  )
end

---Shade a color toward black (light background) or white (dark background) by
---`|value|`. The polarity is chosen from `vim.o.background` so the same call
---darkens on light themes and lightens on dark themes.
---@param color string hex to shade (`#rrggbb`)
---@param value number blend magnitude, 0..1 (sign ignored)
---@param base? string override the shade target (defaults to black/white by bg)
---@return string shaded hex (`#RRGGBB`)
function M.shade(color, value, base)
  if vim.o.background == "light" then
    if base == nil then
      base = "#000000"
    end

    return M.mix(color, base, math.abs(value))
  else
    if base == nil then
      base = "#ffffff"
    end

    return M.mix(color, base, math.abs(value))
  end
end

return M
