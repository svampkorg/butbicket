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
local NS = vim.api.nvim_create_namespace("butbicket_flavour_playground")
local SWATCH = "██" -- two full blocks; U+2588 is 3 bytes each
local BG_SWATCH = "Ab" -- text on a background swatch, to preview fg/bg contrast

-- Accent-role order comes straight from flavour, so the knob list and serialize
-- output can never drift from the roles the generator actually supports.
local ACCENT_ROLES = flavour.ROLE_ORDER

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
-- Locked roles split into two display families: the diff identities and the
-- diagnostic/status identities. Everything else is a normal accent (or a bg role).
local DIFF_ROLES = { added = true, changed = true, removed = true }
for _, role in ipairs(ACCENT_ROLES) do
  local surface = flavour.ROLE_SURFACE[role]
  local locked = flavour.ROLE_LOCKED[role]
  local prefix
  if locked then
    prefix = DIFF_ROLES[role] and "diff." or "diag."
  elseif surface == "bg" then
    prefix = "ui."
  else
    prefix = "accent."
  end
  KNOBS[#KNOBS + 1] = {
    name = role,
    label = prefix .. role,
    kind = "accent",
    step = 5,
    surface = surface, -- "fg" (solid swatch) or "bg" (text-on-color swatch)
    locked = locked, -- diff identities: frozen from the hue wheel until pinned
  }
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

-- A small git-diff demo appended to the sample so the diff.* roles (and the
-- derived line backgrounds) are visible in the float without a real git buffer
-- or a signs plugin. Each line gets a DiffAdd/Change/Delete line background and
-- a sign coloured by the Added/Changed/Removed foreground groups; all recolor
-- live with the flavour.
local DIFF_DEMO = {
  {
    text = "  local inserted = true",
    line = "DiffAdd",
    sign = "+",
    sfg = "Added",
  },
  {
    text = '  local modified = "edit"',
    line = "DiffChange",
    sign = "~",
    sfg = "Changed",
  },
  {
    text = "  local deleted = nil",
    line = "DiffDelete",
    sign = "-",
    sfg = "Removed",
  },
}

-- A diagnostics demo, same idea as the diff demo: each line gets a
-- DiagnosticLine{Error,Warn,Info,Hint} background, a gutter sign coloured by the
-- matching Diagnostic{Error,Warn,Info,Hint} fg, and an eol virtual message in the
-- virtual-text group — so the error/warn/info/hint roles are all visible and
-- recolor live with the flavour.
local DIAG_DEMO = {
  {
    text = "  danger()",
    line = "DiagnosticLineError",
    sign = "E",
    grp = "DiagnosticError",
    vt = "DiagnosticVirtualTextError",
    msg = "undefined global",
  },
  {
    text = "  shady()",
    line = "DiagnosticLineWarn",
    sign = "W",
    grp = "DiagnosticWarn",
    vt = "DiagnosticVirtualTextWarn",
    msg = "unused result",
  },
  {
    text = "  note()",
    line = "DiagnosticLineInfo",
    sign = "I",
    grp = "DiagnosticInfo",
    vt = "DiagnosticVirtualTextInfo",
    msg = "shadowed local",
  },
  {
    text = "  tip()",
    line = "DiagnosticLineHint",
    sign = "H",
    grp = "DiagnosticHint",
    vt = "DiagnosticVirtualTextHint",
    msg = "prefer :method()",
  },
}

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

-- Right-pad a string to a fixed *display* width. Lua's %-Ns pads by byte count,
-- which misaligns multibyte glyphs (the `°` after degree values, the ⚠ mark), so
-- the value/contrast columns drift. strdisplaywidth counts cells, keeping them
-- flush.
local function pad_disp(s, w)
  local pad = w - vim.fn.strdisplaywidth(s)
  return pad > 0 and (s .. string.rep(" ", pad)) or s
end

-- Column widths for the knob rows. LABEL_W fits the longest label
-- ("accent.punctuation" = 18); VAL_W fits a hex/`(auto)`/degrees value.
local LABEL_W = 18
local VAL_W = 8

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

  -- Normal buffer text, used both as the readout numerator for bg roles and as
  -- the glyph color painted on their swatches (what sits on a real match).
  local text = (is_hex(gen.mainText) and gen.mainText)
    or (is_hex(gen.emphasisText) and gen.emphasisText)
    or "#ffffff"

  local lines, warn = {}, false
  lines[#lines + 1] = " butbicket · flavour playground"
  lines[#lines + 1] = ""
  local fg_ratio = is_hex(gen.emphasisText)
      and contrast.ratio(gen.emphasisText, bg)
    or 0
  lines[#lines + 1] = (" fg/bg contrast  %.1f"):format(fg_ratio)
  lines[#lines + 1] = ""

  -- The color a knob currently resolves to (bg/fg from the seed, accents from
  -- the graded palette), or nil for the pure-numeric knobs.
  local function knob_color(k)
    if k.kind == "hex" then
      return session.opts[k.name]
    elseif k.kind == "accent" then
      return gen[flavour.ROLE_KEYS[k.name][1]]
    end
  end

  session.knob_line = {}
  local swatches = {}
  for i, k in ipairs(KNOBS) do
    local marker = (i == session.focus) and ">" or " "
    local val = knob_value_str(session, k)
    local suffix = ""
    local color = knob_color(k)
    local is_bg = k.surface == "bg"
    if k.kind == "accent" and is_hex(color) then
      -- fg roles grade the color on the background; bg roles grade normal text
      -- painted on the color (the readable-match question).
      local r = is_bg and contrast.ratio(text, color)
        or contrast.ratio(color, bg)
      if r < AA then
        warn = true
      end
      suffix = ("  %4.1f%s"):format(r, r < AA and " ⚠" or "")
    end
    -- swatch cell: fg roles show a solid block; bg roles show text on the color
    -- (so you see the fg/bg contrast); numeric knobs are blank.
    local cell = "  "
    if is_hex(color) then
      cell = is_bg and BG_SWATCH or SWATCH
    end
    lines[#lines + 1] = ("%s %s %s %s%s"):format(
      marker,
      cell,
      pad_disp(k.label, LABEL_W),
      pad_disp(val, VAL_W),
      suffix
    )
    session.knob_line[i] = #lines
    if is_hex(color) then
      swatches[#swatches + 1] =
        { row = #lines - 1, hex = color, idx = i, bg = is_bg }
    end
  end

  lines[#lines + 1] = ""
  if warn then
    lines[#lines + 1] = " ⚠ = below AA (4.5) on this background"
    lines[#lines + 1] = ""
  end
  lines[#lines + 1] = " j/k move · h/l nudge · p pin · P all"
  lines[#lines + 1] = " e edit · c color · a accept · q cancel"

  local buf = session.panel.buf
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  -- Paint each swatch with its exact resolved color. Groups are (re)defined
  -- every render because colorscheme()'s `hi clear` wipes them each apply.
  vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
  for _, s in ipairs(swatches) do
    local grp = "ButbicketPgSwatch" .. s.idx
    if s.bg then
      pcall(vim.api.nvim_set_hl, 0, grp, { bg = s.hex, fg = text })
    else
      pcall(vim.api.nvim_set_hl, 0, grp, { fg = s.hex })
    end
    -- swatch starts at byte col 2 ("> "); the cell is SWATCH / BG_SWATCH wide
    local width = s.bg and #BG_SWATCH or #SWATCH
    pcall(vim.api.nvim_buf_set_extmark, buf, NS, s.row, 2, {
      end_col = 2 + width,
      hl_group = grp,
    })
  end

  if vim.api.nvim_win_is_valid(session.panel.win) then
    local win = session.panel.win
    local ln = session.knob_line[session.focus]
    pcall(vim.api.nvim_win_set_cursor, win, { ln, 0 })

    -- Overflow footer: floats have no native scrollbar, so when the knob list is
    -- taller than the window the panel scrolls with the focused knob; show how
    -- many rows are hidden above / below the viewport so "there is more" reads.
    local total = #lines
    local footer = ""
    if total > (session.panel_h or total) then
      local top = vim.fn.line("w0", win)
      local bot = vim.fn.line("w$", win)
      local parts = {}
      if top > 1 then
        parts[#parts + 1] = "↑ " .. (top - 1)
      end
      if bot < total then
        parts[#parts + 1] = (total - bot) .. " ↓"
      end
      if #parts > 0 then
        footer = " " .. table.concat(parts, "   ") .. " "
      end
    end
    pcall(
      vim.api.nvim_win_set_config,
      win,
      { footer = footer, footer_pos = footer ~= "" and "right" or nil }
    )
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

-- The exact color an accent role resolves to right now (the hex its swatch
-- shows), or nil if it isn't a paintable hex. Pinning writes this verbatim.
local function resolved_accent(session, role)
  local hex = graded_palette(session)[flavour.ROLE_KEYS[role][1]]
  return is_hex(hex) and hex or nil
end

-- Pin the focused accent to the exact color its swatch currently shows, so the
-- global hue knobs (hue_shift/base_hue/n_hues) stop moving it — spin the wheel,
-- freeze the roles you like, keep spinning the rest. A hex pin overrides the
-- generator verbatim (L/C/H all frozen). A second `p` on an already-hex-pinned
-- role clears it back to auto. Only accent knobs pin; others are a no-op.
local function pin(session)
  local k = KNOBS[session.focus]
  if k.kind ~= "accent" then
    notify(k.label .. " is not an accent role — nothing to pin")
    return
  end
  if is_hex(session.opts.accents[k.name]) then
    session.opts.accents[k.name] = nil
    notify(("accent.%s unpinned (auto)"):format(k.name))
  else
    local hex = resolved_accent(session, k.name)
    if not hex then
      notify("no resolved color to pin for " .. k.label, vim.log.levels.WARN)
      return
    end
    session.opts.accents[k.name] = hex
    notify(("accent.%s pinned %s"):format(k.name, hex))
  end
  refresh(session)
end

-- Freeze every currently-unpinned accent at its resolved color at once, so a
-- whole wheel position can be locked in before spinning the numeric knobs on.
local function pin_all(session)
  local n = 0
  for _, role in ipairs(ACCENT_ROLES) do
    if not is_hex(session.opts.accents[role]) then
      local hex = resolved_accent(session, role)
      if hex then
        session.opts.accents[role] = hex
        n = n + 1
      end
    end
  end
  notify(
    ("pinned %d accent%s at current colors"):format(n, n == 1 and "" or "s")
  )
  refresh(session)
end

-- ── lifecycle ──────────────────────────────────────────────────────────────

local close_color_editor -- forward decl (defined with the color editor below)

local function close(session, restore)
  if session.closing then
    return
  end
  session.closing = true
  if session.color_editor then
    close_color_editor(session.color_editor, true)
  end
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

  -- Re-apply through the :colorscheme COMMAND, not the bare colorscheme()
  -- function. The function applies highlights directly and never fires the
  -- ColorScheme autocmd, so listeners (incline's refresh, user autocmds) go
  -- stale; :colorscheme sources the colors file — which re-reads config.flavour,
  -- so the accepted/restored look is preserved — and fires ColorScheme natively,
  -- exactly like a manual `:colorscheme butbicket`. Done once on exit only (not
  -- per live keystroke, which would thrash those listeners and flicker).
  --
  -- On restore, reset config.flavour to its exact prior raw state first (nil
  -- falls back to the setup metatable = the user's real flavour). On accept, the
  -- raw shadow already holds the accepted opts and is intentionally kept.
  if restore then
    config.flavour = session.prev_flavour
  end
  local target = (restore and session.prev_colors_name)
    or vim.g.colors_name
    or "butbicket"
  pcall(vim.cmd.colorscheme, target)
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

-- ── OKLch color editor ───────────────────────────────────────────────────--
--
-- A small float for color knobs (bg/fg + accents). Line 1 holds the hex as
-- plain, editable buffer text with a swatch — so an external picker (ccc.nvim,
-- oklch-color-picker) run under the cursor, or a hand edit, updates it just like
-- any buffer; TextChanged parses it back. Below it, L/C/H channel rows nudge
-- with h/l (OKLch matches the palette engine, so nudges stay perceptually even
-- and in gamut). Every change live-applies to the parent flavour.

local COLOR_CHANNELS = {
  { key = "l", label = "L", step = 2, min = 0, max = 100 },
  { key = "c", label = "C", step = 0.5, min = 0, max = 40 },
  { key = "h", label = "H", step = 5, deg = true },
}

local function set_knob_color(session, k, hex)
  if k.kind == "hex" then
    session.opts[k.name] = hex
  else
    session.opts.accents[k.name] = hex
  end
end

-- Color a color knob resolves to for editing: the seed hex for bg/fg, an
-- explicit accent pin, or (for an auto/degrees accent) its resolved color.
local function knob_edit_color(session, k)
  if k.kind == "hex" then
    return session.opts[k.name]
  end
  local v = session.opts.accents[k.name]
  if is_hex(v) then
    return v
  end
  return graded_palette(session)[flavour.ROLE_KEYS[k.name][1]]
end

local function lch_of(hex)
  local x = oklab.hex_to_oklch(hex)
  return { l = x.l, c = x.c, h = x.h or 0 }
end

local function render_color_editor(ed, keep_hexline)
  local lch = lch_of(ed.hex)
  local tail = {}
  tail[#tail + 1] = ""
  for i, ch in ipairs(COLOR_CHANNELS) do
    local marker = (ed.focus == i + 1) and ">" or " " -- focus 1 == hex line
    local v = lch[ch.key]
    local shown = ch.deg and (fmt_num(math.floor(v + 0.5)) .. "°")
      or ("%.1f"):format(v)
    tail[#tail + 1] = ("%s %s  %s"):format(marker, ch.label, shown)
  end
  tail[#tail + 1] = ""
  tail[#tail + 1] = " j/k focus · h/l nudge"
  tail[#tail + 1] = " <CR> apply · q cancel"

  ed.rendering = true
  if keep_hexline then
    vim.api.nvim_buf_set_lines(ed.buf, 1, -1, false, tail)
  else
    local hexline = (ed.focus == 1 and ">" or " ")
      .. " "
      .. ed.hex
      .. "  "
      .. SWATCH
    vim.api.nvim_buf_set_lines(
      ed.buf,
      0,
      -1,
      false,
      vim.list_extend({ hexline }, tail)
    )
  end
  ed.rendering = false

  -- swatch after the hex on line 0 ("> " + hex + "  ")
  vim.api.nvim_buf_clear_namespace(ed.buf, NS, 0, 1)
  pcall(vim.api.nvim_set_hl, 0, "ButbicketPgEditSwatch", { fg = ed.hex })
  local scol = 2 + #ed.hex + 2
  pcall(vim.api.nvim_buf_set_extmark, ed.buf, NS, 0, scol, {
    end_col = scol + #SWATCH,
    hl_group = "ButbicketPgEditSwatch",
  })
end

local function editor_commit(ed)
  set_knob_color(ed.parent, ed.knob, ed.hex)
  refresh(ed.parent)
end

local function nudge_channel(ed, dir)
  local ch = COLOR_CHANNELS[math.max(ed.focus - 1, 1)] -- hex line nudges L
  local lch = lch_of(ed.hex)
  local v = lch[ch.key] + dir * ch.step
  lch[ch.key] = ch.deg and (v % 360) or clamp(v, ch.min, ch.max)
  ed.hex = oklab.oklch_to_hex(lch)
  editor_commit(ed)
  render_color_editor(ed, false)
end

local function on_editor_text(ed)
  if ed.rendering then
    return
  end
  local line0 = vim.api.nvim_buf_get_lines(ed.buf, 0, 1, false)[1] or ""
  local hex = line0:match("#%x%x%x%x%x%x")
  if hex and hex:lower() ~= ed.hex:lower() then
    ed.hex = hex
    editor_commit(ed)
    render_color_editor(ed, true) -- leave the line the user is editing intact
  end
end

function close_color_editor(ed, keep)
  if ed.closing then
    return
  end
  ed.closing = true
  pcall(vim.api.nvim_del_augroup_by_id, ed.augroup)
  if not keep then
    if ed.knob.kind == "hex" then
      ed.parent.opts[ed.knob.name] = ed.orig
    else
      ed.parent.opts.accents[ed.knob.name] = ed.orig
    end
    if not ed.parent.closing then
      refresh(ed.parent)
    end
  end
  if ed.win and vim.api.nvim_win_is_valid(ed.win) then
    pcall(vim.api.nvim_win_close, ed.win, true)
  end
  if ed.buf and vim.api.nvim_buf_is_valid(ed.buf) then
    pcall(vim.api.nvim_buf_delete, ed.buf, { force = true })
  end
  ed.parent.color_editor = nil
  if vim.api.nvim_win_is_valid(ed.parent.panel.win) then
    pcall(vim.api.nvim_set_current_win, ed.parent.panel.win)
  end
end

local function open_color_editor(session)
  if session.color_editor then
    return
  end
  local k = KNOBS[session.focus]
  if k.kind ~= "hex" and k.kind ~= "accent" then
    notify(k.label .. " is not a color — press e to set a value")
    return
  end
  local start = knob_edit_color(session, k)
  if not is_hex(start) then
    notify("no color to edit for " .. k.label)
    return
  end

  local ed = {
    parent = session,
    knob = k,
    hex = start,
    orig = (k.kind == "hex") and session.opts[k.name]
      or session.opts.accents[k.name],
    focus = 2, -- start on the L channel
  }
  ed.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[ed.buf].filetype = "butbicket-flavour-color"

  local pc = vim.api.nvim_win_get_config(session.panel.win)
  ed.win = make_float(ed.buf, {
    enter = true,
    row = (pc.row or 2) + 4,
    col = (pc.col or 2) + 6,
    width = 28,
    height = 8,
    title = " " .. k.label .. " ",
  })

  local function m(lhs, fn)
    vim.keymap.set(
      "n",
      lhs,
      fn,
      { buffer = ed.buf, nowait = true, silent = true }
    )
  end
  m("j", function()
    ed.focus = math.min(ed.focus + 1, 1 + #COLOR_CHANNELS)
    render_color_editor(ed, false)
  end)
  m("k", function()
    ed.focus = math.max(ed.focus - 1, 1)
    render_color_editor(ed, false)
  end)
  for _, lhs in ipairs({ "l", "<Right>" }) do
    m(lhs, function()
      nudge_channel(ed, 1)
    end)
  end
  for _, lhs in ipairs({ "h", "<Left>" }) do
    m(lhs, function()
      nudge_channel(ed, -1)
    end)
  end
  m("<CR>", function()
    close_color_editor(ed, true)
  end)
  for _, lhs in ipairs({ "q", "<Esc>" }) do
    m(lhs, function()
      close_color_editor(ed, false)
    end)
  end

  ed.augroup =
    vim.api.nvim_create_augroup("butbicket_flavour_color", { clear = true })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = ed.augroup,
    buffer = ed.buf,
    callback = function()
      on_editor_text(ed)
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = ed.augroup,
    buffer = ed.buf,
    callback = function()
      close_color_editor(ed, true)
    end,
  })

  session.color_editor = ed
  render_color_editor(ed, false)
  pcall(vim.api.nvim_win_set_cursor, ed.win, { 1, 2 }) -- on the hex, for pickers
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

  -- `prev_flavour` is the raw key, restored verbatim on close (nil falls back
  -- to the setup metatable). `active` is the *effective* flavour — a table here
  -- means the user has a flavour set (via setup or a prior accept), so we seed
  -- the knobs from it instead of starting neutral.
  local prev_flavour = rawget(config, "flavour")
  local active = config.flavour

  -- Capture the canonical (unflavoured) palette to grade from and size the
  -- readout against, without disturbing the user's real config beyond the one
  -- raw key we restore on close.
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

  local seed = type(active) == "table" and active or {}
  local session = {
    base = base,
    opts = {
      background = is_hex(seed.background) and seed.background or seed_bg,
      foreground = is_hex(seed.foreground) and seed.foreground
        or base.emphasisText,
      hue_shift = seed.hue_shift or 0,
      chroma_mult = seed.chroma_mult or 1,
      n_hues = seed.n_hues,
      base_hue = seed.base_hue or 0,
      accents = vim.deepcopy(seed.accents or {}),
    },
    focus = 1,
    prev_flavour = prev_flavour,
    prev_colors_name = vim.g.colors_name,
    panel = {},
    example = {},
  }

  -- example content, built before geometry so the float can size to its length
  local elines = vim.split(SAMPLE:gsub("^\n", ""), "\n", { plain = true })
  elines[#elines + 1] = ""
  elines[#elines + 1] = "-- git diff preview"
  local diff_row0 = #elines -- 0-based row of the first demo line
  for _, d in ipairs(DIFF_DEMO) do
    elines[#elines + 1] = d.text
  end
  elines[#elines + 1] = ""
  elines[#elines + 1] = "-- diagnostics preview"
  local diag_row0 = #elines -- 0-based row of the first diagnostic line
  for _, d in ipairs(DIAG_DEMO) do
    elines[#elines + 1] = d.text
  end

  -- geometry: panel (narrow) on the left, example (wide) on the right. Each
  -- float sizes to its own content, capped to the screen. Neovim floats have no
  -- native scrollbar, so a too-tall panel scrolls with the focused knob and
  -- render_panel draws an overflow footer showing how many rows are hidden.
  local ui_w, ui_h = vim.o.columns, vim.o.lines
  local max_h = math.max(8, ui_h - 4)
  -- panel rows: title + blank + contrast + blank + knobs + blank + warn + help
  local panel_content = #KNOBS + 9
  local panel_h = math.min(panel_content, max_h)
  local example_h = math.min(#elines, max_h)
  local panel_w = 46
  local example_w = math.min(ui_w - panel_w - 10, 84)
  local total_w = panel_w + example_w + 3
  local col0 = math.max(0, math.floor((ui_w - total_w) / 2))
  local row0 =
    math.max(0, math.floor((ui_h - math.max(panel_h, example_h)) / 2))
  session.panel_h = panel_h

  -- example buffer (real syntax groups paint it via filetype/treesitter)
  local ebuf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(ebuf, 0, -1, false, elines)
  vim.bo[ebuf].filetype = "lua"
  vim.bo[ebuf].modifiable = false
  session.example.buf = ebuf
  session.example.win = make_float(ebuf, {
    enter = false,
    row = row0,
    col = col0 + panel_w + 3,
    width = example_w,
    height = example_h,
    title = " sample.lua ",
  })
  vim.wo[session.example.win].cursorline = false
  vim.wo[session.example.win].signcolumn = "yes" -- 'minimal' float hides it

  -- Paint the diff demo: line background + a gutter sign per line. Extmarks
  -- reference the hl groups by name, so they re-resolve when the flavour applies
  -- (no need to redo this on every refresh).
  for i, d in ipairs(DIFF_DEMO) do
    pcall(vim.api.nvim_buf_set_extmark, ebuf, NS, diff_row0 + i - 1, 0, {
      line_hl_group = d.line,
      sign_text = d.sign,
      sign_hl_group = d.sfg,
    })
  end
  for i, d in ipairs(DIAG_DEMO) do
    pcall(vim.api.nvim_buf_set_extmark, ebuf, NS, diag_row0 + i - 1, 0, {
      line_hl_group = d.line,
      sign_text = d.sign,
      sign_hl_group = d.grp,
      virt_text = { { "  ● " .. d.msg, d.vt } },
      virt_text_pos = "eol",
    })
  end

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
    height = panel_h,
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
  for _, lhs in ipairs({ "l", "<Right>" }) do
    map(pbuf, lhs, function()
      nudge(session, 1)
    end)
  end
  for _, lhs in ipairs({ "h", "<Left>" }) do
    map(pbuf, lhs, function()
      nudge(session, -1)
    end)
  end
  for _, lhs in ipairs({ "e", "<CR>" }) do
    map(pbuf, lhs, function()
      edit(session)
    end)
  end
  map(pbuf, "c", function()
    open_color_editor(session)
  end)
  map(pbuf, "p", function()
    pin(session)
  end)
  map(pbuf, "P", function()
    pin_all(session)
  end)
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
