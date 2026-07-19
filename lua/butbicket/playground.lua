-- Flavour playground: an in-editor floating UI to tune a butbicket flavour with
-- live preview. A control panel float carries the knobs (background/foreground,
-- hue_shift, chroma_mult, n_hues, base_hue, per-role accents) with a live WCAG
-- contrast readout; an example float shows real syntax groups reacting. Accept
-- copies a paste-ready `flavour = { … }` block to the clipboard; cancel restores
-- the previous look.
--
-- No side effects on `require` — the UI is built only when `open()` is called.
--
-- Live loop: the flavour is applied by writing `config.flavour` directly (a raw
-- key that shadows the setup metatable) and re-running `colorscheme()`. This is
-- deliberately NOT `setup{ flavour = … }`, because setup rebuilds the whole
-- config metatable from defaults and would wipe the user's transparent/italics/
-- integrations for the duration of the preview. Writing the one key keeps every
-- other setting intact, and restore is a clean rewrite of the raw key.

local config = require("butbicket.config")
local contrast = require("butbicket.contrast")
local flavour = require("butbicket.flavour")
local oklab = require("butbicket.oklab")

local M = {}

local HEX = "^#%x%x%x%x%x%x$"
local AA = 4.5 -- WCAG AA floor for normal text

-- Stable accent-role order (matches flavour.ROLE_KEYS); also drives serialize.
local ACCENT_ROLES =
  { "keyword", "func", "special", "type", "number", "string", "link", "accent" }

-- Knob table. `neutral` is the value assumed when a numeric knob is unset and
-- the user starts nudging it. Accent knobs read/write `opts.accents[name]`.
local KNOBS = {
  { name = "background", label = "background", kind = "hex", step = 2 },
  { name = "foreground", label = "foreground", kind = "hex", step = 2 },
  {
    name = "hue_shift",
    label = "hue_shift",
    kind = "deg",
    step = 5,
    neutral = 0,
  },
  {
    name = "chroma_mult",
    label = "chroma_mult",
    kind = "num",
    step = 0.05,
    min = 0,
    neutral = 1,
  },
  {
    name = "n_hues",
    label = "n_hues",
    kind = "int",
    step = 1,
    min = 0,
    neutral = 0,
  },
  {
    name = "base_hue",
    label = "base_hue",
    kind = "deg",
    step = 5,
    neutral = 0,
  },
}
for _, role in ipairs(ACCENT_ROLES) do
  KNOBS[#KNOBS + 1] =
    { name = role, label = "accent." .. role, kind = "accent", step = 5 }
end

local SAMPLE = [[
-- flavour playground sample
local Animal = {}
Animal.__index = Animal

function Animal.new(name, legs)
  return setmetatable({ name = name, legs = legs or 4 }, Animal)
end

function Animal:describe()
  local kind = self.legs == 2 and "biped" or "quadruped"
  return string.format("%s is a %s (%d legs)", self.name, kind, self.legs)
end

local zoo = { Animal.new("cat"), Animal.new("stork", 2) }
for i = 1, #zoo do
  print(zoo[i]:describe()) -- TODO: sort by legs
end

if not zoo[1] then
  error("empty zoo!")
end
]]

local P -- the single active session, or nil

local function clamp(x, lo, hi)
  return math.min(math.max(x, lo), hi)
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "butbicket flavour" })
end

local function is_hex(v)
  return type(v) == "string" and v:match(HEX) ~= nil
end

local function fmt_num(x)
  if x == math.floor(x) then
    return tostring(math.floor(x))
  end
  return ("%.4g"):format(x)
end

-- Render the current opts as a paste-ready Lua table expression. Only knobs
-- that deviate from their neutral value are emitted; bg/fg are always present
-- (flavour.generate requires them).
local function serialize(opts)
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
    for _, role in ipairs(ACCENT_ROLES) do
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

M.serialize = serialize -- exposed for tests

-- Apply the current opts globally by shadowing config.flavour (see file header)
-- and re-running the colorscheme. Everything on screen re-tones instantly.
local function apply(session)
  config.flavour = session.opts
  require("butbicket").colorscheme()
end

-- Build the flavoured palette purely (same transform colorscheme.lua applies),
-- so the panel can read the resulting role colors for its contrast readout.
local function graded_palette(session)
  return flavour.generate_hues(session.base, session.opts)
end

-- ── panel rendering ────────────────────────────────────────────────────────

local function knob_value_str(session, k)
  local opts = session.opts
  if k.kind == "accent" then
    local v = opts.accents[k.name]
    if v == nil then
      return "(auto)"
    end
    return type(v) == "number" and (fmt_num(v) .. "°") or v
  end
  local v = opts[k.name]
  if v == nil then
    return "(auto)"
  end
  if k.kind == "deg" then
    return fmt_num(v) .. "°"
  end
  return type(v) == "number" and fmt_num(v) or tostring(v)
end

local function render_panel(session)
  local gen = graded_palette(session)
  local bg = is_hex(gen.editorBackground) and gen.editorBackground
    or session.opts.background

  local lines, warn = {}, false
  lines[#lines + 1] = " butbicket · flavour playground"
  lines[#lines + 1] = ""
  local fg_ratio = is_hex(gen.emphasisText)
      and contrast.ratio(gen.emphasisText, bg)
    or 0
  lines[#lines + 1] = (" fg/bg contrast  %.1f"):format(fg_ratio)
  lines[#lines + 1] = ""

  session.knob_line = {}
  for i, k in ipairs(KNOBS) do
    local marker = (i == session.focus) and "›" or " "
    local val = knob_value_str(session, k)
    local suffix = ""
    if k.kind == "accent" then
      local key = flavour.ROLE_KEYS[k.name][1]
      local hex = gen[key]
      if is_hex(hex) then
        local r = contrast.ratio(hex, bg)
        local flag = r < AA and " ⚠" or ""
        if r < AA then
          warn = true
        end
        suffix = ("  %4.1f%s"):format(r, flag)
      end
    end
    lines[#lines + 1] = ("%s %-14s %s%s"):format(marker, k.label, val, suffix)
    session.knob_line[i] = #lines
  end

  lines[#lines + 1] = ""
  if warn then
    lines[#lines + 1] = " ⚠ = below AA (4.5) on this background"
    lines[#lines + 1] = ""
  end
  lines[#lines + 1] = " j/k move · -/+ nudge · e edit"
  lines[#lines + 1] = " a accept (copy) · q cancel"

  local buf = session.panel.buf
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  if vim.api.nvim_win_is_valid(session.panel.win) then
    local ln = session.knob_line[session.focus]
    pcall(vim.api.nvim_win_set_cursor, session.panel.win, { ln, 0 })
  end
end

local function refresh(session)
  apply(session)
  render_panel(session)
end

-- ── interaction ──────────────────────────────────────────────────────────--

local function move(session, delta)
  session.focus = ((session.focus - 1 + delta) % #KNOBS) + 1
  render_panel(session)
end

local function nudge(session, dir)
  local k = KNOBS[session.focus]
  local opts = session.opts
  if k.kind == "num" or k.kind == "int" or k.kind == "deg" then
    local cur = opts[k.name]
    if cur == nil then
      cur = k.neutral
    end
    local v = cur + dir * k.step
    if k.min then
      v = math.max(v, k.min)
    end
    if k.kind == "int" then
      v = math.floor(v + 0.5)
    end
    if k.kind == "deg" then
      v = v % 360
    end
    opts[k.name] = v
  elseif k.kind == "hex" then
    -- nudge the seed's perceptual lightness; the whole re-tone span shifts
    local lch = oklab.hex_to_oklch(opts[k.name])
    opts[k.name] = oklab.oklch_to_hex({
      l = clamp(lch.l + dir * k.step, 0, 100),
      c = lch.c,
      h = lch.h,
    })
  elseif k.kind == "accent" then
    local cur = opts.accents[k.name]
    if type(cur) == "number" then
      opts.accents[k.name] = (cur + dir * k.step) % 360
    else
      notify(
        ("accent.%s is %s — press e to set a value"):format(
          k.name,
          cur and "a hex" or "auto"
        )
      )
      return
    end
  end
  refresh(session)
end

local function parse_input(k, input)
  if k.kind == "hex" then
    if input:match(HEX) then
      return input
    end
    return nil, "expected a #rrggbb hex color"
  end
  if k.kind == "accent" then
    if input == "" or input == "auto" then
      return "clear"
    end
    if input:match(HEX) then
      return input
    end
    local n = tonumber(input)
    if n then
      return n % 360
    end
    return nil, "expected a hex color, degrees, or 'auto'"
  end
  -- numeric knobs
  if input == "" and k.name == "n_hues" then
    return "clear" -- empty clears n_hues back to auto (keep original hues)
  end
  local n = tonumber(input)
  if not n then
    return nil, "expected a number"
  end
  if k.min then
    n = math.max(n, k.min)
  end
  if k.kind == "int" then
    n = math.floor(n + 0.5)
  end
  if k.kind == "deg" then
    n = n % 360
  end
  return n
end

local function edit(session)
  local k = KNOBS[session.focus]
  local cur = knob_value_str(session, k)
  local default = ""
  if k.kind == "accent" then
    local v = session.opts.accents[k.name]
    default = v and (type(v) == "number" and fmt_num(v) or v) or ""
  elseif is_hex(session.opts[k.name]) then
    default = session.opts[k.name]
  elseif type(session.opts[k.name]) == "number" then
    default = fmt_num(session.opts[k.name])
  end
  vim.ui.input({
    prompt = k.label .. " (" .. cur .. ") = ",
    default = default,
  }, function(input)
    if input == nil then
      return
    end
    local value, err = parse_input(k, vim.trim(input))
    if err then
      notify(err, vim.log.levels.WARN)
      return
    end
    if k.kind == "accent" then
      session.opts.accents[k.name] = value ~= "clear" and value or nil
    elseif value == "clear" then
      session.opts[k.name] = nil
    else
      session.opts[k.name] = value
    end
    refresh(session)
  end)
end

-- ── lifecycle ──────────────────────────────────────────────────────────────

local function close(session, restore)
  if session.closing then
    return
  end
  session.closing = true
  pcall(vim.api.nvim_del_augroup_by_id, session.augroup)
  for _, w in ipairs({ session.panel.win, session.example.win }) do
    if w and vim.api.nvim_win_is_valid(w) then
      pcall(vim.api.nvim_win_close, w, true)
    end
  end
  for _, b in ipairs({ session.panel.buf, session.example.buf }) do
    if b and vim.api.nvim_buf_is_valid(b) then
      pcall(vim.api.nvim_buf_delete, b, { force = true })
    end
  end
  if restore then
    -- restore the exact raw state of config.flavour (nil falls back to the
    -- setup metatable, i.e. the user's real flavour) and re-apply.
    config.flavour = session.prev_flavour
    require("butbicket").colorscheme()
    if session.prev_colors_name and session.prev_colors_name ~= "butbicket" then
      pcall(vim.cmd.colorscheme, session.prev_colors_name)
    end
  end
  P = nil
end

local function accept(session)
  local block = "flavour = " .. serialize(session.opts)
  local ok = pcall(vim.fn.setreg, "+", block)
  if not ok then
    pcall(vim.fn.setreg, '"', block)
  end
  close(session, false) -- keep the tuned flavour applied
  notify("flavour copied to clipboard:\n" .. block)
end

local function map(buf, lhs, fn)
  vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, silent = true })
end

local function make_float(buf, opts)
  return vim.api.nvim_open_win(buf, opts.enter, {
    relative = "editor",
    row = opts.row,
    col = opts.col,
    width = opts.width,
    height = opts.height,
    style = "minimal",
    border = "rounded",
    title = opts.title,
    title_pos = "center",
  })
end

function M.open()
  if P then
    if vim.api.nvim_win_is_valid(P.panel.win) then
      vim.api.nvim_set_current_win(P.panel.win)
    end
    return
  end

  if vim.g.colors_name ~= "butbicket" then
    require("butbicket").colorscheme()
  end

  -- Capture the canonical (unflavoured) palette to grade from and to size the
  -- readout against, without disturbing the user's real config beyond the one
  -- raw key we restore on close.
  local prev_flavour = rawget(config, "flavour")
  config.flavour = false
  package.loaded["butbicket.colorscheme"] = nil
  local base = vim.deepcopy(require("butbicket.colorscheme"))

  local fallback_bg = (vim.o.background == "light") and "#ffffff" or "#101214"
  local seed_bg = is_hex(base.editorBackground) and base.editorBackground
    or fallback_bg
  if not is_hex(base.editorBackground) then
    notify(
      "transparent background — previewing on " .. seed_bg,
      vim.log.levels.WARN
    )
  end

  local session = {
    base = base,
    opts = {
      background = seed_bg,
      foreground = base.emphasisText,
      hue_shift = 0,
      chroma_mult = 1,
      n_hues = nil,
      base_hue = 0,
      accents = {},
    },
    focus = 1,
    prev_flavour = prev_flavour,
    prev_colors_name = vim.g.colors_name,
    panel = {},
    example = {},
  }

  -- geometry: panel (narrow) on the left, example (wide) on the right
  local ui_w, ui_h = vim.o.columns, vim.o.lines
  local height = math.min(ui_h - 6, 28)
  local panel_w = 42
  local example_w = math.min(ui_w - panel_w - 10, 84)
  local total_w = panel_w + example_w + 3
  local col0 = math.max(0, math.floor((ui_w - total_w) / 2))
  local row0 = math.max(0, math.floor((ui_h - height) / 2))

  -- example buffer (real syntax groups paint it via filetype/treesitter)
  local ebuf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(
    ebuf,
    0,
    -1,
    false,
    vim.split(SAMPLE:gsub("^\n", ""), "\n", { plain = true })
  )
  vim.bo[ebuf].filetype = "lua"
  vim.bo[ebuf].modifiable = false
  session.example.buf = ebuf
  session.example.win = make_float(ebuf, {
    enter = false,
    row = row0,
    col = col0 + panel_w + 3,
    width = example_w,
    height = height,
    title = " sample.lua ",
  })
  vim.wo[session.example.win].cursorline = false

  -- panel buffer (interactive)
  local pbuf = vim.api.nvim_create_buf(false, true)
  vim.bo[pbuf].filetype = "butbicket-flavour"
  vim.bo[pbuf].modifiable = false
  session.panel.buf = pbuf
  session.panel.win = make_float(pbuf, {
    enter = true,
    row = row0,
    col = col0,
    width = panel_w,
    height = height,
    title = " flavour ",
  })
  vim.wo[session.panel.win].cursorline = true

  -- keymaps (panel buffer)
  map(pbuf, "j", function()
    move(session, 1)
  end)
  map(pbuf, "<Down>", function()
    move(session, 1)
  end)
  map(pbuf, "k", function()
    move(session, -1)
  end)
  map(pbuf, "<Up>", function()
    move(session, -1)
  end)
  for _, lhs in ipairs({ "l", "+", "=", "<Right>" }) do
    map(pbuf, lhs, function()
      nudge(session, 1)
    end)
  end
  for _, lhs in ipairs({ "h", "-", "_", "<Left>" }) do
    map(pbuf, lhs, function()
      nudge(session, -1)
    end)
  end
  for _, lhs in ipairs({ "e", "<CR>" }) do
    map(pbuf, lhs, function()
      edit(session)
    end)
  end
  map(pbuf, "a", function()
    accept(session)
  end)
  for _, lhs in ipairs({ "q", "<Esc>" }) do
    map(pbuf, lhs, function()
      close(session, true)
    end)
  end

  -- closing either window (however triggered) cancels + restores
  session.augroup = vim.api.nvim_create_augroup(
    "butbicket_flavour_playground",
    { clear = true }
  )
  vim.api.nvim_create_autocmd("WinClosed", {
    group = session.augroup,
    callback = function(ev)
      local w = tonumber(ev.match)
      if w == session.panel.win or w == session.example.win then
        close(session, not session.closing and true)
      end
    end,
  })

  P = session
  refresh(session)
end

function M.close()
  if P then
    close(P, true)
  end
end

return M
