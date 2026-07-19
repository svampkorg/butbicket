-- Flavour generator: re-tone the canonical butbicket palette into a new base.
--
-- A flavour keeps butbicket's structure and hue relationships but re-bases the
-- whole palette onto a new background/foreground pair. Every color's perceptual
-- lightness (OKLab) is remapped from the canonical bg->fg span onto the new
-- bg->fg span; hue and chroma are preserved (optionally rotated/scaled), so the
-- result is recognisably butbicket in a different key. Because it transforms the
-- existing palette table key-for-key, no semantic key can go missing.
--
-- This is a build/tooling helper (see scripts/gen-flavour.lua); it is pure and
-- takes the palette as an argument rather than requiring it, so it never
-- triggers a colorscheme load.

local oklab = require("butbicket.oklab")

local M = {}

local HEX = "^#%x%x%x%x%x%x$"

local function clamp(x, lo, hi)
  return math.min(math.max(x, lo), hi)
end

-- Syntax-identity roles that `n_hues` / `accents` may re-hue, and the palette
-- keys each role owns. Semantic-meaning colors (errorText/warningText/
-- successText and the diff added/removed/changed families) are intentionally
-- absent: they stay locked to their hue so "error is red" survives any flavour.
M.ROLE_KEYS = {
  keyword = { "keyword", "syntaxKeyword" },
  func = { "method", "syntaxFunction" },
  special = { "specialKeyword", "purple", "dark_purple" },
  type = { "type" },
  number = { "number", "syntaxNumber" },
  string = { "stringText" },
  link = { "linkText", "blue" },
  accent = { "hotpink" },
}
local ROLE_KEYS = M.ROLE_KEYS

local function circ_dist(a, b)
  local d = math.abs((a - b) % 360)
  return math.min(d, 360 - d)
end

local function nearest_slot(h, slots)
  local best, best_d = slots[1], circ_dist(h, slots[1])
  for i = 2, #slots do
    local d = circ_dist(h, slots[i])
    if d < best_d then
      best, best_d = slots[i], d
    end
  end
  return best
end

-- Accept a hue as degrees (number) or read it from a hex string.
local function resolve_hue(v)
  if type(v) == "number" then
    return v % 360
  end
  if type(v) == "string" and v:match(HEX) then
    return require("butbicket.oklab").hex_to_oklch(v).h or 0
  end
  error("flavour: accent hue must be a number (degrees) or a hex string")
end

---@class butbicket.FlavourOpts
---@field background string new base background "#rrggbb"
---@field foreground string new base foreground "#rrggbb"
---@field hue_shift? number degrees to rotate every hue (default 0)
---@field chroma_mult? number multiply every chroma (default 1)
---@field n_hues? number snap accent roles to N evenly-spaced hues (0 = grayscale)
---@field base_hue? number degrees: where the hue slots start (default 0)
---@field accents? table<string, string|number> pin a role to a hex or hue-degrees;
---       roles: keyword, func, special, type, number, string, link, accent
---@field anchor_bg? string canonical bg key (default "editorBackground")
---@field anchor_fg? string canonical fg key (default "emphasisText")

---Generate a re-toned copy of `palette`.
---@param palette table<string, any> the canonical palette (hex string values)
---@param opts butbicket.FlavourOpts
---@return table<string, any> a new palette table (non-hex values passed through)
function M.generate(palette, opts)
  assert(opts and opts.background and opts.foreground, "flavour: need bg + fg")
  local hue_shift = opts.hue_shift or 0
  local chroma_mult = opts.chroma_mult or 1

  -- Read a lightness from `key`, falling back when the value is not a hex
  -- string (e.g. `editorBackground = "none"` under `transparent = true`).
  local function anchor_l(key, fallback)
    local v = palette[key]
    if type(v) == "string" and v:match(HEX) then
      return oklab.lightness(v)
    end
    return oklab.lightness(palette[fallback])
  end

  local l_bg0 = anchor_l(opts.anchor_bg or "editorBackground", "standardBlack")
  local l_fg0 = anchor_l(opts.anchor_fg or "emphasisText", "standardWhite")
  local l_bg1 = oklab.lightness(opts.background)
  local l_fg1 = oklab.lightness(opts.foreground)

  -- Map a canonical lightness onto the new span, preserving relative position.
  -- Colors outside the canonical bg..fg range extrapolate, then clamp to [0;100].
  local span0 = l_fg0 - l_bg0
  local function remap(l)
    if span0 == 0 then
      return l
    end
    local t = (l - l_bg0) / span0
    return clamp(l_bg1 + t * (l_fg1 - l_bg1), 0, 100)
  end

  local out = {}
  for key, value in pairs(palette) do
    if type(value) == "string" and value:match(HEX) then
      local lch = oklab.hex_to_oklch(value)
      out[key] = oklab.oklch_to_hex({
        l = remap(lch.l),
        c = lch.c * chroma_mult,
        h = lch.h and (lch.h + hue_shift) % 360 or nil,
      })
    else
      out[key] = value
    end
  end

  -- Pin the two anchors to the exact requested seeds so the base is honoured.
  out[opts.anchor_bg or "editorBackground"] = opts.background
  out[opts.anchor_fg or "emphasisText"] = opts.foreground

  return out
end

---Generate a flavour and, on top of the re-tone, re-hue the accent roles:
--- - `n_hues`: snap every accent role's hue to the nearest of N evenly-spaced
---   slots around the wheel (mini.hues style). 0 desaturates accents to gray.
--- - `accents`: pin named roles to an exact hue (hex or degrees); pinned roles
---   ignore the slot snapping. Roles not present are generated as normal.
---Each key keeps its own lightness + chroma (grading is preserved); only hue
---moves. Semantic-meaning colors (error/warning/success, diff) are never touched.
---@param palette table<string, any>
---@param opts butbicket.FlavourOpts
---@return table<string, any>
function M.generate_hues(palette, opts)
  local base = M.generate(palette, opts)
  local n = opts.n_hues
  local accents = opts.accents
  if n == nil and accents == nil then
    return base
  end

  local slots
  if n and n > 0 then
    slots = {}
    local start = opts.base_hue or 0
    for i = 0, n - 1 do
      slots[i + 1] = (start + i * 360 / n) % 360
    end
  end

  local out = {}
  for key, value in pairs(base) do
    out[key] = value
  end

  for role, keys in pairs(ROLE_KEYS) do
    local pinned = accents and accents[role]
    for _, key in ipairs(keys) do
      local hex = base[key]
      if type(hex) == "string" and hex:match(HEX) then
        local lch = oklab.hex_to_oklch(hex)
        local hue, chroma = lch.h, lch.c
        if pinned ~= nil then
          hue = resolve_hue(pinned)
        elseif n == 0 then
          chroma = 0
        elseif slots and lch.h then
          hue = nearest_slot(lch.h, slots)
        end
        out[key] = oklab.oklch_to_hex({ l = lch.l, c = chroma, h = hue })
      end
    end
  end

  return out
end

return M
