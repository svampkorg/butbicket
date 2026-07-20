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

-- Roles that the playground exposes, in display / serialize order. Each entry
-- owns one or more palette `keys` and declares:
--   * `surface`: "fg" (default) — a syntax foreground, previewed as a solid
--     swatch, graded color-on-background; or "bg" — a UI background (search,
--     incsearch), previewed as text-on-color and graded text-on-background.
--   * `locked` (optional): a semantic-identity color the flavour hue wheel must
--     never move — `hue_shift`/`chroma_mult`/`n_hues`/`base_hue` all skip it, so
--     it keeps its hue (only its lightness is remapped to fit a new background).
--     It changes ONLY when the user explicitly pins it. Used for the diff
--     add/change/remove identities, which are intrinsically green/blue/red.
-- errorText/warningText/successText are still absent (handled elsewhere).
--
-- `ROLE_KEYS`/`ROLE_ORDER`/`ROLE_SURFACE`/`ROLE_LOCKED` are all derived from this
-- single source below, so they can never drift; a test asserts it.
M.ROLES = {
  { name = "keyword", keys = { "keyword", "syntaxKeyword" } },
  { name = "func", keys = { "method", "syntaxFunction" } },
  { name = "special", keys = { "specialKeyword", "purple", "dark_purple" } },
  { name = "type", keys = { "type" } },
  { name = "number", keys = { "number", "syntaxNumber" } },
  { name = "string", keys = { "stringText" } },
  { name = "link", keys = { "linkText", "blue" } },
  { name = "accent", keys = { "hotpink" } },
  { name = "comment", keys = { "commentText" } },
  -- variable family, minus text_dark (that is body text / mainText — re-hueing
  -- it would tint all normal text, not just variables).
  {
    name = "variable",
    keys = { "variable", "variable_member", "parameter" },
  },
  -- true operators only; brackets/punctuation are a separate color (light_red).
  { name = "operator", keys = { "syntaxOperator" } },
  -- UI backgrounds: hlsearch matches, and the incremental-search / :substitute
  -- preview. Each has a dedicated single-purpose palette key so tuning it never
  -- touches syntax or the diff tint.
  { name = "search", keys = { "searchBase" }, surface = "bg" },
  { name = "incsearch", keys = { "incSearchBase" }, surface = "bg" },
  -- diff identities: locked so hue changes never turn green/blue/red into
  -- something confusing. colorscheme.lua derives the dim/mid backgrounds from
  -- these, so pinning one flows through the whole diff family.
  { name = "added", keys = { "addedBase" }, locked = true },
  { name = "changed", keys = { "changedBase" }, locked = true },
  { name = "removed", keys = { "removedBase" }, locked = true },
}

M.ROLE_KEYS = {}
M.ROLE_ORDER = {}
M.ROLE_SURFACE = {}
M.ROLE_LOCKED = {}
for _, r in ipairs(M.ROLES) do
  M.ROLE_KEYS[r.name] = r.keys
  M.ROLE_ORDER[#M.ROLE_ORDER + 1] = r.name
  M.ROLE_SURFACE[r.name] = r.surface or "fg"
  M.ROLE_LOCKED[r.name] = r.locked or false
end
local ROLE_KEYS = M.ROLE_KEYS

-- Palette keys whose hue + chroma are locked (identity colors): generate() only
-- remaps their lightness. Built from the locked roles above.
local LOCKED_KEYS = {}
for _, r in ipairs(M.ROLES) do
  if r.locked then
    for _, k in ipairs(r.keys) do
      LOCKED_KEYS[k] = true
    end
  end
end

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
---@field accents? table<string, string|number> pin a role to a hex (exact color)
---       or a number (hue degrees, hue-only). Roles: keyword, func, special,
---       type, number, string, link, accent, comment, variable, operator,
---       search, incsearch, added, changed, removed (the last three are locked
---       identities — only an explicit pin here moves them)
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
      local locked = LOCKED_KEYS[key]
      out[key] = oklab.oklch_to_hex({
        -- lightness always remaps (so identity colors stay visible on the new
        -- background); locked keys keep their hue + chroma verbatim.
        l = remap(lch.l),
        c = locked and lch.c or lch.c * chroma_mult,
        h = locked and lch.h or (lch.h and (lch.h + hue_shift) % 360 or nil),
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
--- - `accents`: pin named roles; pinned roles ignore the slot snapping. A pin
---   given as **degrees** (number) rotates hue only, keeping each key's own
---   lightness + chroma (grading preserved). A pin given as a **hex** sets that
---   role's keys to the exact color — so a color chosen in the playground lands
---   verbatim (its lightness/chroma matter, not just its hue).
---Except for exact-hex pins, each key keeps its own lightness + chroma; only hue
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
    -- A hex pin is an exact color; a number pin (or n_hues) only moves hue.
    local exact = type(pinned) == "string" and pinned:match(HEX) and pinned
    for _, key in ipairs(keys) do
      local hex = base[key]
      if type(hex) == "string" and hex:match(HEX) then
        if exact then
          out[key] = exact
        elseif pinned == nil and M.ROLE_LOCKED[role] then
          -- Locked identity, no explicit pin: leave it as generate() produced
          -- (lightness-remapped, hue kept). n_hues/base_hue never touch it.
          out[key] = hex
        else
          local lch = oklab.hex_to_oklch(hex)
          local hue, chroma = lch.h, lch.c
          if pinned ~= nil then
            hue = resolve_hue(pinned) -- degrees: rotate hue only
          elseif n == 0 then
            chroma = 0
          elseif slots and lch.h then
            hue = nearest_slot(lch.h, slots)
          end
          out[key] = oklab.oklch_to_hex({ l = lch.l, c = chroma, h = hue })
        end
      end
    end
  end

  return out
end

return M
