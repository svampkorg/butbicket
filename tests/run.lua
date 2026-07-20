-- Standalone test runner for the butbicket colorscheme.
-- Run with:  nvim -l tests/run.lua
-- No external dependencies (no plenary/busted); uses only the Neovim Lua API.
-- Exits non-zero on any failure so CI can gate on it.

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
local contrast = require("butbicket.contrast")

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

-- OKLab math: hex -> OKLch -> hex must round-trip within 1/255 per channel.
-- Guards the conversion module the palette tooling (flavour, light preview)
-- depends on.
print("\n== oklab round-trip ==")
do
  local oklab = require("butbicket.oklab")
  local function channels(hex)
    return tonumber(hex:sub(2, 3), 16),
      tonumber(hex:sub(4, 5), 16),
      tonumber(hex:sub(6, 7), 16)
  end
  local samples = {
    "#ffffff",
    "#000000",
    "#101214",
    "#fd9891",
    "#7ee2b8",
    "#8fb8f6",
    "#fbc828",
    "#669cf0",
    "#e78178",
    "#bf63f3",
    "#73a130",
    "#ba9420",
  }
  for _, hex in ipairs(samples) do
    local rt = oklab.oklch_to_hex(oklab.hex_to_oklch(hex))
    local r1, g1, b1 = channels(hex)
    local r2, g2, b2 = channels(rt)
    local d = math.max(math.abs(r1 - r2), math.abs(g1 - g2), math.abs(b1 - b2))
    check(d <= 1, string.format("round-trip %s -> %s (Δ%d)", hex, rt, d))
  end
end

-- Flavour generator: a re-toned palette preserves every semantic key and its
-- syntax foregrounds still clear their floor on the new background.
print("\n== flavour generator ==")
do
  vim.o.background = "dark"
  package.loaded["butbicket.colorscheme"] = nil
  local canonical = require("butbicket.colorscheme")
  local flavour = require("butbicket.flavour")

  local p = flavour.generate(canonical, {
    background = "#0d1b2a",
    foreground = "#e2e8f4",
    hue_shift = -8,
  })

  for _, key in ipairs(required_keys) do
    check(p[key] ~= nil, "flavour keeps palette." .. key)
  end

  local bg = p.editorBackground
  for _, pair in ipairs(contrast_pairs(p)) do
    if pair.fg then
      local r = contrast.ratio(pair.fg, bg)
      check(
        r >= pair.floor,
        string.format(
          "flavour %-14s %.2f (floor %.1f)",
          pair.name,
          r,
          pair.floor
        )
      )
    end
  end

  -- n_hues + accents: accents pin a role, semantic-meaning colors stay locked.
  local oklab = require("butbicket.oklab")
  local plain = flavour.generate(canonical, {
    background = "#101214",
    foreground = "#e7e7e8",
  })
  local hued = flavour.generate_hues(canonical, {
    background = "#101214",
    foreground = "#e7e7e8",
    n_hues = 3,
    accents = { keyword = "#c678dd" },
  })
  local function hue(hex)
    return oklab.hex_to_oklch(hex).h or 0
  end
  local function circ(a, b)
    local d = math.abs((a - b) % 360)
    return math.min(d, 360 - d)
  end
  check(
    circ(hue(hued.syntaxKeyword), hue("#c678dd")) < 3,
    "accents pin keyword hue to the requested color"
  )
  -- A hex pin is an exact color (L/C/H), so a color chosen in the playground
  -- lands verbatim — the swatch matches the value. A degrees pin moves hue only.
  local exact = flavour.generate_hues(canonical, {
    background = "#101214",
    foreground = "#e7e7e8",
    accents = { string = "#d3b778" },
  })
  check(
    exact.stringText == "#d3b778",
    "hex-pinned accent lands verbatim (exact color, not hue-only)"
  )
  check(
    hued.errorText == plain.errorText,
    "n_hues leaves semantic errorText locked"
  )
  check(
    hued.successText == plain.successText,
    "n_hues leaves semantic successText locked"
  )
  check(hued.editorBackground ~= nil, "generate_hues keeps a complete palette")

  -- Regression: the `number` role must move `syntaxNumber` too — the Number /
  -- Float / @number highlight groups read that alias, not `number`. Pinning the
  -- role and leaving syntaxNumber behind is an invisible-no-op bug.
  local pinned_num = flavour.generate_hues(canonical, {
    background = "#101214",
    foreground = "#e7e7e8",
    accents = { number = "#00ff00" },
  })
  check(
    pinned_num.syntaxNumber == pinned_num.number
      and pinned_num.syntaxNumber ~= canonical.syntaxNumber,
    "number role re-hues syntaxNumber (the key Number group uses)"
  )

  -- General anti-trap guard, independent of ROLE_KEYS: this maps each role to
  -- the palette key(s) its *headline* highlight groups actually read (audited
  -- from hl-groups.lua). Pinning a role to an exact hex must set every one of
  -- those keys to that hex; if ROLE_KEYS omits one, the group it feeds never
  -- changes (the `number`/`syntaxNumber` bug). When a group starts reading a new
  -- key, add it here — the mismatch then fails loudly instead of shipping.
  local role_group_keys = {
    keyword = { "keyword", "syntaxKeyword" }, -- Statement, Boolean, Define
    func = { "syntaxFunction" }, -- Function, Method
    type = { "type" }, -- Type
    number = { "syntaxNumber" }, -- Number, Float, @number
    string = { "stringText" }, -- String, Character
    link = { "blue" }, -- Tag
    special = { "specialKeyword" }, -- Debug, @debug
    accent = { "hotpink" }, -- MatchParen
    comment = { "commentText" }, -- Comment, SpecialComment, @comment
    variable = { "variable", "variable_member", "parameter" }, -- @variable(.member), Parameter
    operator = { "syntaxOperator" }, -- Operator, Delimiter, Special
  }
  local PIN = "#3366cc"
  for role, keys in pairs(role_group_keys) do
    local out = flavour.generate_hues(canonical, {
      background = "#101214",
      foreground = "#e7e7e8",
      accents = { [role] = PIN }, -- exact-hex pin: deterministic, no hue drift
    })
    for _, key in ipairs(keys) do
      check(out[key] == PIN, string.format("role %-8s drives %s", role, key))
    end
  end

  -- flavour.ROLE_ORDER (drives the playground's knob list) must match ROLE_KEYS
  -- exactly, so the two can never drift.
  local in_order = {}
  for _, role in ipairs(flavour.ROLE_ORDER) do
    in_order[role] = true
  end
  local order_ok = #flavour.ROLE_ORDER == vim.tbl_count(flavour.ROLE_KEYS)
  for role in pairs(flavour.ROLE_KEYS) do
    order_ok = order_ok and in_order[role]
  end
  check(order_ok, "flavour.ROLE_ORDER matches ROLE_KEYS exactly")
end

-- Integration registry: every module loads and returns a highlight table, and
-- the enable/detect gating behaves.
print("\n== integrations ==")
do
  vim.o.background = "dark"
  package.loaded["butbicket.colorscheme"] = nil
  package.loaded["butbicket.integrations"] = nil
  local I = require("butbicket.integrations")
  local cfg = { transparent = false, italics = { bufferline = false } }

  for _, spec in ipairs(I.registry) do
    local ok, hl = pcall(function()
      local mod = require("butbicket.integrations." .. spec.module)
      return spec.wants_config and mod.highlights(cfg) or mod.highlights()
    end)
    check(
      ok and type(hl) == "table",
      "integration " .. spec.name .. " highlights() returns a table"
    )
  end

  -- Gating: nothing is emitted when no plugin is installed / all disabled.
  check(
    next(I.highlights({ integrations = { default = false } })) == nil,
    "default=false emits no groups"
  )
  check(
    next(I.highlights({ integrations = { default = true } })) == nil,
    "no installed plugins emits no groups"
  )
end

-- Flavour playground: pure helpers (no UI). Requiring the module must not open
-- any window, and serialize() must emit a paste-ready, loadable flavour block.
print("\n== playground ==")
do
  local wins_before = #vim.api.nvim_list_wins()
  local pg = require("butbicket.playground")
  check(
    #vim.api.nvim_list_wins() == wins_before,
    "require('butbicket.playground') opens no window"
  )
  check(
    type(pg.open) == "function" and type(pg.serialize) == "function",
    "playground exposes open() + serialize()"
  )

  local opts = {
    background = "#101214",
    foreground = "#e7e7e8",
    hue_shift = 30,
    chroma_mult = 1, -- neutral: must be omitted from output
    n_hues = 0, -- present (0 = grayscale) must survive
    base_hue = 0, -- neutral: omitted
    accents = { keyword = "#c678dd", func = 140 },
  }
  local body = pg.serialize(opts)
  local loader = load("return " .. body)
  check(loader ~= nil, "serialize() output is loadable Lua")
  local t = loader and loader()
  check(t and t.background == "#101214", "serialize round-trips background")
  check(t and t.hue_shift == 30, "serialize round-trips hue_shift")
  check(t and t.chroma_mult == nil, "serialize omits neutral chroma_mult")
  check(t and t.n_hues == 0, "serialize keeps n_hues = 0 (grayscale)")
  check(t and t.base_hue == nil, "serialize omits neutral base_hue")
  check(
    t and t.accents and t.accents.keyword == "#c678dd" and t.accents.func == 140,
    "serialize round-trips accents (hex + degrees)"
  )

  -- The panel builds a knob per flavour.ROLE_ORDER entry and indexes
  -- flavour.ROLE_KEYS[role][1] for its swatch + contrast; a missing entry would
  -- break the render silently.
  local flavour = require("butbicket.flavour")
  local ok_roles = true
  for _, role in ipairs(flavour.ROLE_ORDER) do
    local keys = flavour.ROLE_KEYS[role]
    if type(keys) ~= "table" or type(keys[1]) ~= "string" then
      ok_roles = false
    end
  end
  check(
    ok_roles,
    "every flavour.ROLE_ORDER role has ROLE_KEYS the panel can render"
  )
end

-- Extras generator: emits one file per target, and the output reflects the
-- active flavour (so :ButbicketExtras matches a user's pasted flavour).
print("\n== extras ==")
do
  local extras = require("butbicket.extras")
  check(
    type(extras.generate) == "function" and #extras.TARGETS >= 7,
    "extras exposes generate() + TARGETS"
  )

  local config = require("butbicket.config")
  config.flavour = { background = "#1a1b26", foreground = "#c0caf5" }
  local dir = vim.fn.tempname()
  local written = extras.generate({ dir = dir, variants = { "dark" } })
  config.flavour = nil
  require("butbicket").colorscheme()

  check(
    #written == #extras.TARGETS,
    "generate writes one file per target (" .. #written .. ")"
  )
  local f = io.open(dir .. "/ghostty/butbicket-dark", "r")
  local body = f and f:read("*a")
  if f then
    f:close()
  end
  check(
    body ~= nil and body:match("background = #1A1B26") ~= nil,
    "generated extras reflect the active flavour background"
  )
end

print("")
if #failures > 0 then
  print(("%d check(s) failed"):format(#failures))
  os.exit(1)
end
print("all checks passed")
