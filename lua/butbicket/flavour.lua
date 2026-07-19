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

---@class butbicket.FlavourOpts
---@field background string new base background "#rrggbb"
---@field foreground string new base foreground "#rrggbb"
---@field hue_shift? number degrees to rotate every hue (default 0)
---@field chroma_mult? number multiply every chroma (default 1)
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

return M
