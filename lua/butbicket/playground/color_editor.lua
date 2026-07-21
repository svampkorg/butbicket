-- OKLch color editor: a small float for color knobs (bg/fg + accents). Line 1
-- holds the hex as plain, editable buffer text with a swatch — so an external
-- picker (ccc.nvim, oklch-color-picker) run under the cursor, or a hand edit,
-- updates it just like any buffer; TextChanged parses it back. Below it, L/C/H
-- channel rows nudge with h/l (OKLch matches the palette engine, so nudges stay
-- perceptually even and in gamut). Every change live-applies to the parent
-- flavour via `session.refresh` (injected by the orchestrator to avoid a require
-- cycle).

local flavour = require("butbicket.flavour")
local oklab = require("butbicket.oklab")
local sample = require("butbicket.playground.sample")
local util = require("butbicket.playground.util")

local KNOBS = sample.KNOBS
local NS = util.NS
local SWATCH = util.SWATCH
local clamp = util.clamp
local fmt_num = util.fmt_num
local is_hex = util.is_hex
local notify = util.notify

local M = {}

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
  return util.graded_palette(session)[flavour.ROLE_KEYS[k.name][1]]
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
  ed.parent.refresh(ed.parent)
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

function M.close(ed, keep)
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
      ed.parent.refresh(ed.parent)
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

function M.open(session)
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
  ed.win = util.make_float(ed.buf, {
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
    M.close(ed, true)
  end)
  for _, lhs in ipairs({ "q", "<Esc>" }) do
    m(lhs, function()
      M.close(ed, false)
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
      M.close(ed, true)
    end,
  })

  session.color_editor = ed
  render_color_editor(ed, false)
  pcall(vim.api.nvim_win_set_cursor, ed.win, { 1, 2 }) -- on the hex, for pickers
end

return M
