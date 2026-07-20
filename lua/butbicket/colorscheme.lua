local config = require("butbicket.config")

-- NOTE: saved for reference
-- local fromBitBucket = {
--   keyword = '#FD9891',
--   method = '#7EE2B8',
--   number = '#8FB8F6',
--   stringText = '#FBC828',
--   abyss = '#151A17',
--   dark_charcoal = '#262E2A',
--   charcoal = '#37423F',
--   dark_slate = '#495554',
--   slate = '#5B6768',
--   slate_gray = '#6E777B',
--   steel_gray = '#81888D',
--   annotation = '#96999E',
--   comment = '#AAABAF',
--   variable = '#B6B7BA',
--   parenthesis = '#CECFD2',
--   text = '#E7E7E8',
--   selected = '#89576E',
--   selected_inactive = '#464646',
--   type = '#CFE1FD',
--   blue = '#669CF0',
--   green = '#73A130',
--   red = '#E78178',
--   mustard = '#BA9420',
--   yellow = '#FBC828',
--   purple = '#BF63F3',
--   base = '#101214',
--   base_1 = '#18191A', -- ts context
--   base_2 = '#1F1F21', -- panels
--   base_3 = '#2D2D2D', -- dead area
--   base_4 = '#303134', -- floats/pum
--   separator = '#46474B',
--   cursorline = '#2B2B2E',
--   added = '#164B35',
--   added_dim = '#212A27',
--   removed = '#5D1F1A',
--   removed_dim = '#2E2322',
--   changed = '#183053',
--   changed_dim = '#20252B',
-- }

local colorscheme = {
  standardWhite = "#ffffff",
  standardBlack = "#101214",
}

colorscheme.keyword = "#FD9891"
colorscheme.method = "#7EE2B8"
colorscheme.number = "#8FB8F6"
colorscheme.stringText = "#FBC828"
colorscheme.text = "#E7E7E8"
colorscheme.text_dark = "#D4D4D4"
colorscheme.parenthesis = "#CECFD2"
colorscheme.variable = "#B6B7BA"
colorscheme.variable_member = "#96999E"
colorscheme.parameter = "#AAABAF"
colorscheme.selected = "#89576E"
colorscheme.selected_inactive = "#464646"
colorscheme.annotation = "#89576E" -- @attribute / PreCondit (own key, tunable)
colorscheme.type = "#CFE1FD"
colorscheme.blue = "#669CF0"
colorscheme.green = "#73A130"
colorscheme.red = "#E78178"
colorscheme.light_red = "#FEC195"
colorscheme.searchBase = "#7B6215" -- Search / CurSearch + flash current label
colorscheme.incSearchBase = "#DA70D6" -- IncSearch / Substitute
colorscheme.diffTextBase = "#7B6215" -- DiffText intra-line change tint
colorscheme.mustard = "#BA9420"
colorscheme.yellow = "#FBC828"
colorscheme.light_yellow = "#FFD700"
colorscheme.dark_purple = "#BF63F3"
colorscheme.purple = "#DA70D6"
colorscheme.base = "#101214"
colorscheme.base_1 = "#18191A"
colorscheme.base_2 = "#1F1F21"
colorscheme.base_3 = "#2D2D2D"
colorscheme.base_4 = "#303134"
colorscheme.separator = "#46474B"
colorscheme.cursorline = "#2B2B2E"
-- Diff identity colors (green/blue/red). The fg (`*_bright`) and the mid/dim
-- backgrounds (`*`, `*_dim`) are derived from these at the end of this file, so
-- everything diff-related tracks one source and stays in lockstep with a flavour
-- customization. These identities are locked from the flavour hue wheel.
colorscheme.addedBase = "#1A5C41"
colorscheme.changedBase = "#1F3E6B"
colorscheme.removedBase = "#7B2922"
-- Diagnostic identity colors + success status. Each diagnostic level owns a
-- semantic key instead of borrowing a syntax/link/function color, so spinning a
-- syntax role's hue no longer drags DiagnosticHint (was `method`) or
-- DiagnosticInfo (was `blue`). Seeded from the canonical colors they used to
-- read. Locked from the flavour hue wheel like the diff family; customizable via
-- an explicit pin. The integration aliases errorText/warningText/successText are
-- derived from these at the end of this file.
colorscheme.errorBase = colorscheme.red
colorscheme.warnBase = colorscheme.mustard
colorscheme.infoBase = colorscheme.blue
colorscheme.hintBase = colorscheme.method
colorscheme.successBase = colorscheme.green
colorscheme.abyss = "#171717"
colorscheme.dark_charcoal = "#2A2A2A"
colorscheme.charcoal = "#3D3D3D"
colorscheme.dark_slate = "#515151"
colorscheme.slate = "#636363"
colorscheme.slate_gray = "#757575"
colorscheme.steel_gray = "#878787"
colorscheme.hotpink = "#ff007c"

if vim.o.background == "light" then
  -- LIGHT
  -- Remap the raw base palette to light-appropriate hues. hl-groups.lua and the
  -- integrations reference several of these keys directly (not only via the
  -- semantic aliases below), so without this block their dark values bleed
  -- through and render near-invisible on a white background. All foreground
  -- values here clear WCAG AA (>=4.5) on white; see tests/run.lua.
  -- syntax foreground
  colorscheme.text = "#2a2a2a"
  colorscheme.text_dark = "#2a2a2a" -- Property / Field
  colorscheme.keyword = "#c0392b" -- Statement / Keyword
  colorscheme.type = "#1e4f8f"
  colorscheme.method = "#0f6e5a"
  colorscheme.number = "#1a5fb4"
  colorscheme.variable = "#454b52"
  colorscheme.variable_member = "#5f636a"
  colorscheme.parameter = "#5f636a"
  colorscheme.parenthesis = "#5f636a"
  colorscheme.light_red = "#93591a" -- punctuation / brackets
  colorscheme.purple = "#9b2393"
  colorscheme.mustard = "#9c6400"
  colorscheme.blue = "#1976d2"
  colorscheme.green = "#22863a"
  colorscheme.red = "#c0392b"
  colorscheme.hotpink = "#d1006a" -- MatchParen / flash
  colorscheme.selected = "#8a3d5f"
  colorscheme.annotation = "#8a3d5f" -- @attribute / PreCondit
  -- surfaces
  colorscheme.base_1 = "#f0f0f0"
  colorscheme.base_2 = "#eaeaea"
  colorscheme.base_3 = "#dcdcdc"
  colorscheme.base_4 = "#ededed"
  colorscheme.cursorline = "#e8e8e8"
  colorscheme.searchBase = "#d9b23a" -- Search / CurSearch + flash current label
  colorscheme.incSearchBase = "#9b2393" -- IncSearch / Substitute
  colorscheme.diffTextBase = "#d9b23a" -- DiffText intra-line change tint
  -- diff identities (GitHub-light); backgrounds derived at end of file
  colorscheme.addedBase = "#1a7f37"
  colorscheme.changedBase = "#0969da"
  colorscheme.removedBase = "#cf222e"
  -- diagnostic identities (light); AA on white. error unified to the AA red
  colorscheme.errorBase = "#d32f2f"
  colorscheme.warnBase = "#b26a00"
  colorscheme.infoBase = "#1976d2"
  colorscheme.hintBase = "#0f6e5a"
  colorscheme.successBase = "#22863a"

  -- use #FDFDFD as white
  colorscheme.editorBackground = config.transparent and "none" or "#ffffff"
  colorscheme.sidebarBackground = "#dddddd"
  colorscheme.popupBackground = "#f6f6f6"
  colorscheme.floatingWindowBackground = "#e0e0e0"
  colorscheme.menuOptionBackground = "#ededed"

  colorscheme.mainText = "#616161"
  colorscheme.emphasisText = "#212121"
  colorscheme.commandText = "#333333"
  colorscheme.inactiveText = "#9e9e9e"
  colorscheme.disabledText = "#d0d0d0"
  colorscheme.lineNumberText = "#a1a1a1"
  colorscheme.selectedText = "#424242"
  colorscheme.inactiveSelectionText = "#757575"

  colorscheme.windowBorder = "#c2c3c5"
  colorscheme.focusedBorder = "#aaaaaa"
  colorscheme.emphasizedBorder = "#999999"

  colorscheme.syntaxFunction = "#6871ff"
  colorscheme.syntaxError = "#d6656a"
  colorscheme.syntaxKeyword = "#9966cc"
  colorscheme.linkText = "#1976d2"
  colorscheme.commentText = "#848484"
  colorscheme.stringText = "#b35c00" -- darkened to AA (4.7) on white
  colorscheme.warningEmphasis = "#cd9731"
  colorscheme.specialKeyword = "#800080"
  colorscheme.syntaxOperator = "#a1a1a1"
  colorscheme.foregroundEmphasis = "#000000"
  colorscheme.terminalGray = "#333333"
  colorscheme.syntaxNumber = colorscheme.number
else
  -- DARK
  colorscheme.editorBackground = config.transparent and "none"
    or colorscheme.base
  colorscheme.sidebarBackground = colorscheme.base_2
  colorscheme.popupBackground = colorscheme.base_2
  colorscheme.floatingWindowBackground = colorscheme.base_1
  colorscheme.menuOptionBackground = colorscheme.base_3

  colorscheme.mainText = colorscheme.text_dark
  colorscheme.emphasisText = colorscheme.text
  colorscheme.commandText = colorscheme.variable
  colorscheme.inactiveText = colorscheme.slate
  colorscheme.disabledText = colorscheme.variable_member
  colorscheme.lineNumberText = colorscheme.dark_slate
  colorscheme.selectedText = colorscheme.selected
  colorscheme.inactiveSelectionText = colorscheme.selected_inactive

  colorscheme.windowBorder = colorscheme.separator
  colorscheme.focusedBorder = colorscheme.slate
  colorscheme.emphasizedBorder = colorscheme.blue

  colorscheme.syntaxError = colorscheme.red
  colorscheme.syntaxFunction = colorscheme.method
  colorscheme.syntaxKeyword = colorscheme.keyword
  colorscheme.linkText = colorscheme.blue
  colorscheme.stringText = colorscheme.stringText
  colorscheme.warningEmphasis = colorscheme.yellow
  colorscheme.specialKeyword = colorscheme.method
  colorscheme.commentText = colorscheme.slate
  colorscheme.syntaxOperator = colorscheme.parenthesis
  colorscheme.foregroundEmphasis = colorscheme.type
  colorscheme.syntaxNumber = colorscheme.number
  colorscheme.terminalGray = colorscheme.base
end
colorscheme.floatBorder = colorscheme.dark_slate

-- Opt-in flavour: re-tone the whole palette onto a new base while keeping
-- butbicket's hue relationships (see butbicket.flavour). Applied last so it
-- transforms the fully-resolved palette, then transparency is re-honoured.
local result = colorscheme
if type(config.flavour) == "table" then
  result =
    require("butbicket.flavour").generate_hues(colorscheme, config.flavour)
  if config.transparent then
    result.editorBackground = "none"
  end
end

-- Derive the diff family from the three locked identity colors, AFTER the
-- flavour so it operates on the final palette. `*_bright` is the identity fg;
-- the mid (`*`) and dim (`*_dim`) backgrounds are the identity blended toward
-- the editor background. Every diff highlight + integration reads these, so a
-- pinned identity flows through the whole family. Lighter alphas on a light
-- background keep the backgrounds pale; heavier on dark keep them readable.
do
  local utils = require("butbicket.utils")
  local ebg = result.editorBackground
  if type(ebg) ~= "string" or not ebg:match("^#%x%x%x%x%x%x$") then
    ebg = (vim.o.background == "light") and "#ffffff" or "#101214"
  end
  local mid, dim = 0.72, 0.42
  if vim.o.background == "light" then
    mid, dim = 0.24, 0.1
  end
  for _, t in ipairs({ "added", "changed", "removed" }) do
    local base = result[t .. "Base"]
    result[t .. "_bright"] = base
    result[t] = utils.mix(base, ebg, mid)
    result[t .. "_dim"] = utils.mix(base, ebg, dim)
  end
end

-- Integration foreground aliases derived from the locked diagnostic/status
-- identities, AFTER the flavour, so a pinned identity flows to every integration
-- that reads errorText/warningText/successText and stays in lockstep with the
-- diagnostic groups (which read *Base directly).
result.errorText = result.errorBase
result.warningText = result.warnBase
result.successText = result.successBase

return result
