-- OKLab / OKLch color helpers. Pure Lua, no Neovim API — usable from the theme
-- tooling (scripts/) and from tests.
--
-- Conversion math and the lightness-correction estimate are lifted from
-- nvim-mini/mini.colors (MIT License, Copyright (c) 2023 Evgeni Chasnovski):
--   https://github.com/nvim-mini/mini.nvim  (lua/mini/colors.lua)
-- Original derivations by Björn Ottosson:
--   https://bottosson.github.io/posts/oklab/
--
-- Coordinate ranges: l in [0; 100] (perceptually corrected), a/b unbounded,
-- c (chroma) in [0; 100] (far less in-gamut), h (hue) in [0; 360).

local M = {}

local function clip(x, lo, hi)
  return math.min(math.max(x, lo), hi)
end

local function round(x)
  return math.floor(x + 0.5)
end

-- l, m, s are always non-negative here, so a plain power is safe.
local function cuberoot(x)
  return x ^ (1 / 3)
end

local tau = 2 * math.pi
local function rad2deg(x)
  return (x % tau) * 360 / tau
end
local function deg2rad(x)
  return (x % 360) * tau / 360
end

-- sRGB gamma <-> linear, input in [0; 1].
local function to_linear(x)
  return 0.04045 < x and ((x + 0.055) / 1.055) ^ 2.4 or (x / 12.92)
end
local function from_linear(x)
  return 0.0031308 >= x and (12.92 * x) or (1.055 * x ^ (1 / 2.4) - 0.055)
end

-- Perceptual lightness correction (Ottosson's "new lightness estimate").
local k1, k2 = 0.206, 0.03
local k3 = (1 + k1) / (1 + k2)
local function correct_l(x)
  x = 0.01 * x
  return 100
    * (0.5 * (k3 * x - k1 + math.sqrt((k3 * x - k1) ^ 2 + 4 * k2 * k3 * x)))
end
local function correct_l_inv(x)
  x = 0.01 * x
  return 100 * (x / k3) * (x + k1) / (x + k2)
end

-- HEX <-> RGB in [0; 255]
local function hex2rgb(hex)
  local dec = tonumber(hex:sub(2), 16)
  local b = dec % 256
  local g = math.floor(dec / 256) % 256
  local r = math.floor(dec / 65536)
  return { r = r, g = g, b = b }
end

local function rgb2hex(rgb)
  return string.format(
    "#%02x%02x%02x",
    clip(round(rgb.r), 0, 255),
    clip(round(rgb.g), 0, 255),
    clip(round(rgb.b), 0, 255)
  )
end

-- RGB in [0; 255] <-> OKLab
local function rgb2oklab(rgb)
  local r = to_linear(rgb.r / 255)
  local g = to_linear(rgb.g / 255)
  local b = to_linear(rgb.b / 255)

  local l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
  local m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
  local s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

  local l_, m_, s_ = cuberoot(l), cuberoot(m), cuberoot(s)

  local L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
  local A = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
  local B = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_

  if math.abs(A) < 1e-4 then
    A = 0
  end
  if math.abs(B) < 1e-4 then
    B = 0
  end

  return { l = correct_l(100 * L), a = 100 * A, b = 100 * B }
end

local function oklab2rgb(lab)
  local L = 0.01 * correct_l_inv(lab.l)
  local A, B = 0.01 * lab.a, 0.01 * lab.b

  local l_ = L + 0.3963377774 * A + 0.2158037573 * B
  local m_ = L - 0.1055613458 * A - 0.0638541728 * B
  local s_ = L - 0.0894841775 * A - 1.2914855480 * B

  local l = l_ * l_ * l_
  local m = m_ * m_ * m_
  local s = s_ * s_ * s_

  local r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
  local g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
  local b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

  return {
    r = 255 * from_linear(r),
    g = 255 * from_linear(g),
    b = 255 * from_linear(b),
  }
end

-- OKLab <-> OKLch
local function oklab2oklch(lab)
  local c = math.sqrt(lab.a ^ 2 + lab.b ^ 2)
  local h = nil
  if c > 0 then
    h = rad2deg(math.atan2(lab.b, lab.a))
  end
  return { l = lab.l, c = c, h = h }
end

local function oklch2oklab(lch)
  if lch.c <= 0 or lch.h == nil then
    return { l = lch.l, a = 0, b = 0 }
  end
  return {
    l = lch.l,
    a = lch.c * math.cos(deg2rad(lch.h)),
    b = lch.c * math.sin(deg2rad(lch.h)),
  }
end

local function in_gamut(rgb)
  local eps = 0.5
  return rgb.r >= -eps
    and rgb.r <= 255 + eps
    and rgb.g >= -eps
    and rgb.g <= 255 + eps
    and rgb.b >= -eps
    and rgb.b <= 255 + eps
end

-- Public API -----------------------------------------------------------------

---@class butbicket.Oklch
---@field l number lightness [0; 100]
---@field c number chroma [0; ~40]
---@field h number|nil hue [0; 360) (nil for grays)

---@param hex string "#rrggbb"
---@return butbicket.Oklch
function M.hex_to_oklch(hex)
  return oklab2oklch(rgb2oklab(hex2rgb(hex)))
end

---Convert an OKLch color back to hex. If the color falls outside the sRGB
---gamut, chroma is reduced (preserving lightness and hue) via binary search
---until it fits — this keeps perceived lightness stable, which matters most
---when re-lightening dark colors for a light background.
---@param lch butbicket.Oklch
---@return string
function M.oklch_to_hex(lch)
  local function rgb_at(c)
    return oklab2rgb(oklch2oklab({ l = lch.l, c = c, h = lch.h }))
  end

  if in_gamut(rgb_at(lch.c)) then
    return rgb2hex(rgb_at(lch.c))
  end

  local lo, hi = 0, lch.c
  for _ = 1, 24 do
    local mid = 0.5 * (lo + hi)
    if in_gamut(rgb_at(mid)) then
      lo = mid
    else
      hi = mid
    end
  end
  return rgb2hex(rgb_at(lo))
end

---Perceptual lightness of a hex color, in [0; 100].
---@param hex string
---@return number
function M.lightness(hex)
  return M.hex_to_oklch(hex).l
end

---Return `hex` with its OKLch channels overridden by any present in `over`
---(l/c/h). Hue/chroma preserved unless overridden; result is gamut-clipped.
---@param hex string
---@param over butbicket.Oklch
---@return string
function M.adjust(hex, over)
  local lch = M.hex_to_oklch(hex)
  return M.oklch_to_hex({
    l = over.l or lch.l,
    c = over.c or lch.c,
    h = over.h or lch.h,
  })
end

return M
