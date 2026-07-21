-- Generate terminal / bat / Claude Code theme files from the butbicket palette.
--
-- The palette is read back from a live `colorscheme()` apply, so whatever flavour
-- is active in `config.flavour` flows through automatically — a user who pastes a
-- flavour into their setup can regenerate matching extras with `:ButbicketExtras`.
-- The 16 ANSI slots come from `vim.g.terminal_color_*`, so every file matches
-- what Neovim's :terminal uses (set_terminal_colors() stays the single source).
--
-- `scripts/gen-terminals.lua` is a thin CLI wrapper over `M.generate`; the repo's
-- committed extras/ (canonical, no flavour) are produced there and CI-gated.
--
-- The per-target emitters live in sibling modules (extras/terminals.lua,
-- extras/bat.lua, extras/claude_code.lua); this file collects the palette and
-- drives them. Each emitter is `(t) -> { ext = string, body = string }`.

local M = {}

local function upper(hex)
  return (hex or ""):upper()
end

-- Apply a variant and collect everything the emitters need. Honors the active
-- flavour because colorscheme() re-reads config.flavour on every apply.
local function collect(background)
  vim.o.background = background
  require("butbicket").colorscheme()

  package.loaded["butbicket.colorscheme"] = nil
  local c = require("butbicket.colorscheme")

  local ansi = {}
  for i = 0, 15 do
    ansi[i] = upper(vim.g["terminal_color_" .. i])
  end

  return {
    name = "butbicket-" .. background,
    light = background == "light",
    ansi = ansi, -- 0..15
    bg = upper(vim.g.terminal_color_background),
    fg = upper(vim.g.terminal_color_foreground),
    cursor = upper(c.mainText),
    sel_bg = upper(c.selected),
    sel_fg = upper(c.emphasisText),
    accent = upper(c.linkText),

    -- syntax palette (bat .tmTheme)
    keyword = upper(c.keyword),
    string = upper(c.stringText),
    func = upper(c.syntaxFunction),
    number = upper(c.syntaxNumber or c.number),
    type = upper(c.type),
    variable = upper(c.variable),
    parameter = upper(c.parameter),
    comment = upper(c.commentText),
    operator = upper(c.syntaxOperator),
    boolean = upper(c.syntaxKeyword),
    punctuation = upper(c.light_red),
    tag = upper(c.linkText),
    attribute = upper(c.method),
    line_bg = upper(c.cursorline),

    -- ui / status / diffs (Claude Code custom theme)
    error = upper(c.errorText),
    warning = upper(c.warningText),
    success = upper(c.successText),
    purple = upper(c.purple),
    added = upper(c.added),
    removed = upper(c.removed),
    added_dim = upper(c.added_dim),
    removed_dim = upper(c.removed_dim),
    added_word = upper(c.added_bright),
    removed_word = upper(c.removed_bright),
    border = upper(c.windowBorder),
    focus_border = upper(c.focusedBorder),
    emph_border = upper(c.emphasizedBorder),
    inactive = upper(c.inactiveText),
  }
end

-- The emitter registry, merged from the per-target modules. Each module returns
-- a `{ target = fn }` map; a target name is unique across modules.
local emitters = {}
for _, mod in ipairs({ "terminals", "bat", "claude_code" }) do
  for target, fn in pairs(require("butbicket.extras." .. mod)) do
    emitters[target] = fn
  end
end

-- Every target the generator can emit, in a stable order.
M.TARGETS =
  { "ghostty", "kitty", "alacritty", "wezterm", "warp", "claude-code", "bat" }

local function write(path, contents)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local fd = assert(io.open(path, "w"))
  fd:write(contents)
  fd:close()
end

---Generate extra theme files. Honors the active `config.flavour`.
---@param opts? { dir?: string, variants?: string[], targets?: string[], on_write?: fun(path: string) }
---@return string[] written absolute/relative paths, in generation order
function M.generate(opts)
  opts = opts or {}
  local dir = opts.dir or "extras"
  local variants = opts.variants or { "dark", "light" }
  local targets = opts.targets or M.TARGETS

  -- Restore the user's live view afterwards: collect() flips vim.o.background
  -- and reloads the colorscheme, which is fine for the CLI but not for a command
  -- run inside a session.
  local saved_bg = vim.o.background

  local written = {}
  for _, v in ipairs(variants) do
    local t = collect(v)
    for _, term in ipairs(targets) do
      local emit = emitters[term]
      if not emit then
        error("unknown target: " .. term)
      end
      local out = emit(t)
      local path = ("%s/%s/%s%s"):format(dir, term, t.name, out.ext)
      write(path, out.body)
      written[#written + 1] = path
      if opts.on_write then
        opts.on_write(path)
      end
    end
  end

  if vim.o.background ~= saved_bg then
    vim.o.background = saved_bg
    require("butbicket").colorscheme()
  end

  return written
end

return M
