-- Flavour serialization + the knob-state builder. Pure helpers (no UI), so they
-- are unit-tested directly via the playground module's re-exposed M.serialize /
-- M.serialize_variants.

local sample = require("butbicket.playground.sample")
local util = require("butbicket.playground.util")

local is_hex = util.is_hex
local fmt_num = util.fmt_num

local M = {}

-- Build a normalized opts table (the knob state) from a flavour recipe and the
-- canonical palette for a background. Missing background/foreground fall back to
-- that base's anchors — so seeding one polarity from another (recipe with its
-- bg/fg stripped) re-anchors onto the new base while carrying every transform.
function M.default_opts(recipe, base)
  recipe = type(recipe) == "table" and recipe or {}
  local anchor_bg = (is_hex(base.editorBackground) and base.editorBackground)
    or (is_hex(recipe.background) and recipe.background)
    or "#101214"
  return {
    background = is_hex(recipe.background) and recipe.background or anchor_bg,
    foreground = is_hex(recipe.foreground) and recipe.foreground
      or base.emphasisText,
    hue_shift = recipe.hue_shift or 0,
    chroma_mult = recipe.chroma_mult or 1,
    n_hues = recipe.n_hues,
    base_hue = recipe.base_hue or 0,
    accents = vim.deepcopy(recipe.accents or {}),
  }
end

-- Render the current opts as a paste-ready Lua table expression. Only knobs
-- that deviate from their neutral value are emitted; bg/fg are always present
-- (flavour.generate requires them).
function M.serialize(opts)
  local lines = { "{" }
  local function kv(k, v)
    lines[#lines + 1] = ("  %s = %s,"):format(k, v)
  end
  kv("background", ("%q"):format(opts.background))
  kv("foreground", ("%q"):format(opts.foreground))
  if opts.hue_shift and opts.hue_shift ~= 0 then
    kv("hue_shift", fmt_num(opts.hue_shift))
  end
  if opts.chroma_mult and opts.chroma_mult ~= 1 then
    kv("chroma_mult", fmt_num(opts.chroma_mult))
  end
  if opts.n_hues ~= nil then
    kv("n_hues", fmt_num(opts.n_hues))
  end
  if opts.base_hue and opts.base_hue ~= 0 then
    kv("base_hue", fmt_num(opts.base_hue))
  end
  if opts.accents and next(opts.accents) ~= nil then
    lines[#lines + 1] = "  accents = {"
    for _, role in ipairs(sample.ACCENT_ROLES) do
      local v = opts.accents[role]
      if v ~= nil then
        local rv = type(v) == "number" and fmt_num(v) or ("%q"):format(v)
        lines[#lines + 1] = ("    %s = %s,"):format(role, rv)
      end
    end
    lines[#lines + 1] = "  },"
  end
  lines[#lines + 1] = "}"
  return table.concat(lines, "\n")
end

-- Serialize the per-background variants map to a paste-ready
-- `{ dark = {…}, light = {…} }` expression (only the sides that exist).
function M.serialize_variants(variants)
  local lines = { "{" }
  for _, pol in ipairs({ "dark", "light" }) do
    if variants[pol] then
      local inner = M.serialize(variants[pol]):gsub("\n", "\n  ")
      lines[#lines + 1] = ("  %s = %s,"):format(pol, inner)
    end
  end
  lines[#lines + 1] = "}"
  return table.concat(lines, "\n")
end

return M
