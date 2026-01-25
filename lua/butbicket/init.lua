local bufferline = require 'butbicket.integrations.bufferline'
local haunt = require 'butbicket.integrations.haunt'
local cmp = require 'butbicket.integrations.cmp'
local neogit = require 'butbicket.integrations.neogit'
local blink = require 'butbicket.integrations.blink'
local colorscheme = require 'butbicket.colorscheme'
local config = require 'butbicket.config'
local utils = require 'butbicket.utils'
local theme = {}

local function set_terminal_colors()
  vim.g.terminal_color_0 = colorscheme.editorBackground
  vim.g.terminal_color_1 = colorscheme.syntaxError
  vim.g.terminal_color_2 = colorscheme.successText
  vim.g.terminal_color_3 = colorscheme.warningEmphasis
  vim.g.terminal_color_4 = colorscheme.syntaxFunction
  vim.g.terminal_color_5 = colorscheme.syntaxKeyword
  vim.g.terminal_color_6 = colorscheme.linkText
  vim.g.terminal_color_7 = colorscheme.mainText
  vim.g.terminal_color_8 = colorscheme.inactiveText
  vim.g.terminal_color_9 = colorscheme.errorText
  vim.g.terminal_color_10 = colorscheme.stringText
  vim.g.terminal_color_11 = colorscheme.warningText
  vim.g.terminal_color_12 = colorscheme.syntaxOperator
  vim.g.terminal_color_13 = colorscheme.syntaxError
  vim.g.terminal_color_14 = colorscheme.stringText
  vim.g.terminal_color_15 = colorscheme.commentText
  vim.g.terminal_color_background = colorscheme.editorBackground
  vim.g.terminal_color_foreground = colorscheme.mainText
end

local function set_groups()
  local bg = config.transparent and 'NONE' or colorscheme.editorBackground
  -- local diff_add =
  --   utils.shade(colorscheme.successText, 0.5, colorscheme.editorBackground)
  -- local diff_delete =
  --   utils.shade(colorscheme.syntaxError, 0.5, colorscheme.editorBackground)
  -- local diff_change =
  --   utils.shade(colorscheme.syntaxFunction, 0.5, colorscheme.editorBackground)
  local diff_text =
    utils.shade(colorscheme.old_mustard, 0.5, colorscheme.editorBackground)

  local groups = {
    Normal = { fg = colorscheme.mainText, bg = bg },
    LineNr = { fg = colorscheme.lineNumberText },
    ColorColumn = {
      bg = utils.shade(colorscheme.linkText, 0.5, colorscheme.editorBackground),
    },
    Added = { fg = colorscheme.added },
    Changed = { fg = colorscheme.changed },
    Removed = { fg = colorscheme.removed },
    Conceal = {},
    Cursor = { fg = colorscheme.editorBackground, bg = colorscheme.mainText },
    lCursor = { link = 'Cursor' },
    CursorIM = { link = 'Cursor' },
    CursorLine = { bg = colorscheme.popupBackground },
    CursorColumn = { link = 'CursorLine' },
    Directory = { fg = colorscheme.syntaxFunction },
    DiffAdd = { bg = colorscheme.added_dim },
    DiffChange = { bg = colorscheme.changed_dim },
    DiffDelete = { bg = colorscheme.removed_dim },
    GitSignsAddPreview = { bg = colorscheme.added_dim },
    GitSignsChangePreview = { bg = colorscheme.changed_dim },
    GitSignsDeletePreview = { bg = colorscheme.removed_dim },
    GitSignsAddInline = { fg = colorscheme.added_bright },
    GitSignsChangeInline = { fg = colorscheme.changed_bright },
    GitSignsDeleteInline = { fg = colorscheme.removed_bright },
    DiffText = { bg = diff_text },
    EndOfBuffer = { fg = colorscheme.syntaxKeyword },
    TermCursor = { link = 'Cursor' },
    TermCursorNC = { link = 'Cursor' },
    ErrorMsg = { fg = colorscheme.syntaxError },
    VertSplit = { fg = colorscheme.windowBorder, bg = bg },
    Winseparator = { link = 'VertSplit' },
    SignColumn = { link = 'Normal' },
    Folded = { fg = colorscheme.mainText, bg = colorscheme.base_2 },
    FoldColumn = { link = 'SignColumn' },
    IncSearch = {
      bg = utils.mix(
        colorscheme.purple,
        colorscheme.editorBackground,
        math.abs(0.30)
      ),
    },
    Substitute = { link = 'IncSearch' },
    CursorLineNr = { fg = colorscheme.dark_slate },
    MatchParen = { fg = colorscheme.hotpink, bold = true },
    ModeMsg = { link = 'Normal' },
    MsgArea = { link = 'Normal' },
    MsgSeparator = { link = 'VertSplit' },
    MoreMsg = { fg = colorscheme.syntaxFunction },
    NonText = { fg = utils.shade(colorscheme.editorBackground, 0.75) },
    NormalFloat = { bg = colorscheme.floatingWindowBackground },
    FloatBorder = { bg = colorscheme.floatingWindowBackground, fg = colorscheme.windowBorder },
    PmenuBorder = { bg = colorscheme.floatingWindowBackground, fg = colorscheme.windowBorder },
    NormalNC = { link = 'Normal' },
    Pmenu = { link = 'NormalFloat' },
    PmenuSel = { bg = colorscheme.menuOptionBackground },
    PmenuSbar = {
      bg = utils.shade(
        colorscheme.windowBorder,
        0.5,
        colorscheme.editorBackground
      ),
    },
    PmenuThumb = { bg = utils.shade(colorscheme.editorBackground, 0.20) },
    Question = { fg = colorscheme.syntaxFunction },
    QuickFixLine = { bg = colorscheme.cursorline },
    SpecialKey = { fg = colorscheme.syntaxOperator },
    StatusLine = { fg = colorscheme.mainText, bg = colorscheme.windowBorder },
    StatusLineNC = {
      fg = colorscheme.inactiveText,
      bg = colorscheme.sidebarBackground,
    },
    TabLine = {
      bg = colorscheme.windowBorder,
      fg = colorscheme.inactiveText,
    },
    TabLineFill = { link = 'TabLine' },
    TabLineSel = {
      bg = colorscheme.separator,
      fg = colorscheme.emphasisText,
      bold = true,
    },
    Search = { bg = utils.mix(colorscheme.old_mustard, colorscheme.base_2, 0.4) }, -- = utils.shade(colorscheme.mustard, 0.90, colorscheme.bg) },
    CurSearch = { bg = utils.mix(colorscheme.old_mustard, colorscheme.base_2, 0.8) }, -- = utils.shade(colorscheme.mustard, 0.90, colorscheme.bg) },
    SpellBad = { undercurl = true, sp = colorscheme.syntaxError },
    SpellCap = { undercurl = true, sp = colorscheme.syntaxFunction },
    SpellLocal = { undercurl = true, sp = colorscheme.syntaxKeyword },
    SpellRare = { undercurl = true, sp = colorscheme.warningText },
    Title = { fg = colorscheme.syntaxFunction },
    Visual = {
      bg = colorscheme.menuOptionBackground,
      -- bg = utils.shade(
      --   colorscheme.commentText,
      --   0.20,
      --   colorscheme.editorBackground
      -- ),
    },
    VisualNOS = { link = 'Visual' },
    WarningMsg = { fg = colorscheme.warningText },
    Whitespace = { fg = colorscheme.syntaxOperator },
    WildMenu = { bg = colorscheme.menuOptionBackground },
    Comment = {
      -- fg = utils.shade(
      --   colorscheme.commentText,
      --   0.9,
      --   colorscheme.editorBackground
      -- ),
      fg = colorscheme.commentText,
      italic = config.italics.comments or false,
    },

    SpecialComment = { fg = colorscheme.commentText },
    Constant = { fg = colorscheme.syntaxError },
    String = {
      fg = colorscheme.stringText,
      italic = config.italics.strings or false,
    },
    Character = { fg = colorscheme.stringText },
    Number = { fg = colorscheme.syntaxNumber },
    Boolean = { fg = colorscheme.syntaxKeyword },
    Float = { link = 'Number' },

    Identifier = { fg = colorscheme.steel_gray },
    Function = { fg = colorscheme.syntaxFunction },
    Method = { fg = colorscheme.syntaxFunction },
    Property = { fg = colorscheme.text_dark },
    Field = { link = 'Property' },
    Parameter = { fg = colorscheme.parameter },
    Statement = {
      fg = colorscheme.keyword,
      bold = true,
      italic = config.italics.statements or false,
    },
    Conditional = { fg = colorscheme.syntaxError },
    -- Repeat = {},
    Label = { fg = colorscheme.syntaxFunction },
    Operator = { fg = colorscheme.parenthesis },
    Keyword = {
      link = 'Statement',
      italic = config.italics.keywords or false,
      bold = true,
    },
    Exception = { fg = colorscheme.syntaxError },

    PreProc = { link = 'Keyword' },
    -- Include = {},
    Define = { fg = colorscheme.syntaxKeyword },
    Macro = { link = 'Define' },
    PreCondit = { fg = colorscheme.selected },
    -- PreCondit = { link = 'Label' },

    Type = { fg = colorscheme.type },
    Struct = { link = 'Type' },
    Class = { link = 'Type' },

    -- StorageClass = {},
    -- Structure = {},
    -- Typedef = {},

    Attribute = { link = 'Character' },
    Punctuation = { fg = colorscheme.syntaxOperator },
    Special = { fg = colorscheme.syntaxOperator },

    SpecialChar = { fg = colorscheme.syntaxError },
    Tag = { fg = colorscheme.blue },
    Delimiter = { fg = colorscheme.syntaxOperator },
    -- SpecialComment = {},
    Debug = { fg = colorscheme.specialKeyword },

    Underlined = { underline = true },
    Bold = { bold = true },
    Italic = { italic = true },
    Ignore = { fg = colorscheme.editorBackground },
    Error = { link = 'ErrorMsg' },
    Todo = { fg = colorscheme.warningText, bold = true },

    -- LspReferenceText = {},
    -- LspReferenceRead = {},
    -- LspReferenceWrite = {},
    -- LspCodeLens = {},
    -- LspCodeLensSeparator = {},
    -- LspSignatureActiveParameter = {},

    DiagnosticError = { link = 'Error' },
    DiagnosticWarn = { link = 'WarningMsg' },
    DiagnosticInfo = { fg = colorscheme.blue },
    DiagnosticHint = { fg = colorscheme.method },
    DiagnosticVirtualTextError = { link = 'DiagnosticError' },
    DiagnosticVirtualTextWarn = { link = 'DiagnosticWarn' },
    DiagnosticVirtualTextInfo = { link = 'DiagnosticInfo' },
    DiagnosticVirtualTextHint = { link = 'DiagnosticHint' },
    -- DiagnosticUnderlineError = { undercurl = true, link = 'DiagnosticError' },
    -- DiagnosticUnderlineWarn = { undercurl = true, link = 'DiagnosticWarn' },
    -- DiagnosticUnderlineInfo = { undercurl = true, link = 'DiagnosticInfo' },
    -- DiagnosticUnderlineHint = { undercurl = true, link = 'DiagnosticHint' },
    DiagnosticUnderlineError = {
      undercurl = true,
      fg = colorscheme.syntaxError,
    },
    DiagnosticUnderlineWarn = { undercurl = true, fg = colorscheme.warningText },
    DiagnosticUnderlineInfo = { undercurl = true, fg = colorscheme.blue },
    DiagnosticUnderlineHint = { undercurl = true, fg = colorscheme.method },
    DiagnosticLineError = {
      bg = utils.shade(
        colorscheme.syntaxError,
        0.1,
        colorscheme.editorBackground
      ),
    },
    DiagnosticLineWarn = {
      bg = utils.shade(
        colorscheme.warningText,
        0.1,
        colorscheme.editorBackground
      ),
    },
    DiagnosticLineInfo = {
      bg = utils.shade(colorscheme.blue, 0.1, colorscheme.editorBackground),
    },
    DiagnosticLineHint = {
      bg = utils.shade(colorscheme.method, 0.1, colorscheme.editorBackground),
    },
    -- DiagnosticUnderlineError = { undercurl = true },
    -- DiagnosticUnderlineWarn = { undercurl = true },
    -- DiagnosticUnderlineInfo = { undercurl = true },
    -- DiagnosticUnderlineHint = { undercurl = true },
    -- DiagnosticFloatingError = {},
    -- DiagnosticFloatingWarn = {},
    -- DiagnosticFloatingInfo = {},
    -- DiagnosticFloatingHint = {},
    -- DiagnosticSignError = {},
    -- DiagnosticSignWarn = {},
    -- DiagnosticSignInfo = {},
    -- DiagnosticSignHint = {},

    -- Tree-Sitter groups are defined with an "@" symbol, which must be
    -- specially handled to be valid lua code, we do this via the special
    -- sym function. The following are all valid ways to call the sym function,
    -- for more details see https://www.lua.org/pil/5.html
    --
    -- sym("@text.literal")
    -- sym('@text.literal')
    -- sym"@text.literal"
    -- sym'@text.literal'
    --
    -- For more information see https://github.com/rktjmp/lush.nvim/issues/109

    -- Tree-Sitter Context
    TreesitterContextLineNumber = {
      bg = colorscheme.base_1,
      fg = colorscheme.separator,
    },
    TreesitterContextBottom = {
      cterm = { underline = true },
      sp = colorscheme.base_3,
      underline = true,
    },
    TreesitterContextLineNumberBottom = { link = 'TreesitterContextBottom' },
    TreesitterContextSeparator = {
      bg = colorscheme.base_1,
      fg = colorscheme.base_3,
    },
    TreesitterContext = { bg = colorscheme.base_1 },

    -- NeoTree
    NeoTreeGitAdded = { fg = colorscheme.added_bright },
    NeoTreeGitConflict = { fg = colorscheme.errorText },
    NeoTreeGitDeleted = { fg = colorscheme.removed_bright },
    NeoTreeGitIgnored = { fg = colorscheme.slate_gray },
    NeoTreeGitModified = { fg = colorscheme.mustard }, -- unstaged
    NeoTreeGitStaged = { fg = colorscheme.green },
    NeoTreeGitRenamed = { fg = colorscheme.mustard },
    NeoTreeGitUntracked = { fg = colorscheme.slate_gray },

    ['@text'] = { fg = colorscheme.mainText },
    ['@texcolorscheme.literal'] = { link = 'Property' },
    -- ["@texcolorscheme.reference"] = {},
    ['@texcolorscheme.strong'] = { link = 'Bold' },
    ['@texcolorscheme.italic'] = { link = 'Italic' },
    ['@texcolorscheme.title'] = { link = 'Keyword' },
    ['@texcolorscheme.uri'] = {
      fg = colorscheme.syntaxFunction,
      sp = colorscheme.syntaxFunction,
      underline = true,
    },
    ['@texcolorscheme.underline'] = { link = 'Underlined' },
    ['@symbol'] = { fg = colorscheme.syntaxOperator },
    ['@texcolorscheme.todo'] = { link = 'Todo' },
    ['@comment'] = { link = 'Comment' },
    ['@punctuation'] = { link = 'Punctuation' },
    ['@punctuation.bracket'] = { link = 'Punctuation' }, -- fg = colorscheme.warningEmphasis },
    ['@punctuation.bracket.css'] = { fg = colorscheme.purple }, -- fg = colorscheme.warningEmphasis },
    ['@punctuation.bracket.scss'] = { fg = colorscheme.purple }, -- fg = colorscheme.warningEmphasis },
    -- ['@punctuation.bracket.typescript'] = { fg = colorscheme.light_yellow }, -- fg = colorscheme.warningEmphasis },
    ['@punctuation.delimiter'] = { link = 'Punctuation' }, -- fg = colorscheme.syntaxError },
    ['@punctuation.terminator.statement'] = { link = 'Delimiter' },
    ['@punctuation.special'] = { fg = colorscheme.syntaxError },
    ['@punctuation.separator.keyvalue'] = { link = 'Punctuation' }, -- { fg = colorscheme.syntaxError },

    ['@texcolorscheme.diff.add'] = { bg = colorscheme.added },
    ['@texcolorscheme.diff.delete'] = { bg = colorscheme.removed },

    ['@constant'] = { link = 'Constant' },
    ['@constant.builtin'] = { fg = colorscheme.syntaxFunction },
    ['@constancolorscheme.builtin'] = { link = 'Keyword' },
    -- ["@constancolorscheme.macro"] = {},
    -- ["@define"] = {},
    -- ["@macro"] = {},
    ['@string'] = { link = 'String' },
    ['@string.vue'] = { fg = colorscheme.light_red },
    ['@string.html'] = { fg = colorscheme.light_red },
    ['@string.escape'] = { fg = utils.shade(colorscheme.stringText, 0.45) },
    ['@string.special'] = { fg = utils.shade(colorscheme.syntaxFunction, 0.45) },
    -- ["@character"] = {},
    -- ["@character.special"] = {},
    ['@number'] = { link = 'Number' },
    ['@boolean'] = { link = 'Boolean' },
    -- ["@float"] = {},
    ['@function'] = {
      link = 'Function',
      italic = config.italics.functions or false,
    },
    ['@function.call'] = { link = 'Function' },
    ['@function.builtin'] = { link = 'Function' },
    -- ["@function.macro"] = {},
    ['@parameter'] = { link = 'Parameter' },
    ['@method'] = { link = 'Function' },
    ['@field'] = { link = 'Property' },
    ['@property'] = { link = 'Property' },
    ['@constructor'] = { fg = colorscheme.syntaxFunction },
    -- ["@conditional"] = {},
    -- ["@repeat"] = {},
    ['@label'] = { link = 'Label' },
    ['@operator'] = { link = 'Operator' },
    ['@exception'] = { link = 'Exception' },
    ['@variable'] = {
      fg = colorscheme.variable,
      italic = config.italics.variables or false,
    },
    ['@variable.builtin'] = { fg = colorscheme.emphasisText },
    ['@variable.member'] = {
      fg = colorscheme.variable_member,
      italic = config.italics.variable_members or false,
    },
    ['@variable.parameter'] = {
      fg = colorscheme.parameter,
      italic = config.italics.variable_parameters or false,
    },
    ['@type'] = { link = 'Type' },
    ['@type.definition'] = { fg = colorscheme.variable },
    ['@type.builtin'] = { fg = colorscheme.syntaxFunction },
    ['@type.qualifier'] = { fg = colorscheme.syntaxFunction },
    ['@keyword'] = { link = 'Keyword' },
    -- ["@storageclass"] = {},
    -- ["@structure"] = {},
    ['@namespace'] = { link = 'Type' },
    ['@annotation'] = { link = 'Label' },
    -- ["@include"] = {},
    -- ["@preproc"] = {},
    ['@debug'] = { fg = colorscheme.specialKeyword },
    ['@tag'] = { link = 'Tag' },
    ['@tag.builtin'] = { link = 'Tag' },
    ['@tag.delimiter'] = { fg = colorscheme.syntaxOperator },
    ['@tag.attribute'] = { fg = colorscheme.method },
    ['@tag.jsx.element'] = { fg = colorscheme.syntaxFunction },
    ['@attribute'] = { fg = colorscheme.selected },
    ['@error'] = { link = 'Error' },
    ['@warning'] = { link = 'WarningMsg' },
    ['@info'] = { fg = colorscheme.syntaxFunction },

    -- Specific languages
    -- overrides
    ['@label.json'] = { fg = colorscheme.property }, -- For json
    ['@label.help'] = { link = '@texcolorscheme.uri' }, -- For help files
    ['@texcolorscheme.uri.html'] = { underline = true }, -- For html

    -- semantic highlighting
    ['@lsp.type.namespace'] = { link = '@namespace' },
    ['@lsp.type.type'] = { link = '@type' },
    ['@lsp.type.class'] = { link = '@type' },
    ['@lsp.type.enum'] = { link = '@type' },
    ['@lsp.type.enumMember'] = { fg = colorscheme.syntaxFunction },
    ['@lsp.type.interface'] = { link = '@type' },
    ['@lsp.type.struct'] = { link = '@type' },
    ['@lsp.type.parameter'] = { link = '@parameter' },
    ['@lsp.type.property'] = { link = '@text' },
    ['@lsp.type.function'] = { link = '@function' },
    ['@lsp.type.method'] = { link = '@method' },
    ['@lsp.type.macro'] = { link = '@label' },
    ['@lsp.type.decorator'] = { link = '@label' },
    ['@lsp.typemod.function.declaration'] = { link = '@function' },
    ['@lsp.typemod.function.readonly'] = { link = '@function' },
  }

  -- integrations
  groups = vim.tbl_extend('force', groups, cmp.highlights())
  groups = vim.tbl_extend('force', groups, neogit.highlights())
  groups = vim.tbl_extend('force', groups, haunt.highlights())
  groups = vim.tbl_extend('force', groups, blink.highlights())

  -- overrides
  groups = vim.tbl_extend(
    'force',
    groups,
    type(config.overrides) == 'function' and config.overrides()
      or config.overrides
  )

  for group, parameters in pairs(groups) do
    vim.api.nvim_set_hl(0, group, parameters)
  end
end

function theme.setup(values)
  setmetatable(
    config,
    { __index = vim.tbl_extend('force', config.defaults, values) }
  )

  theme.bufferline = { highlights = {} }
  theme.bufferline.highlights = bufferline.highlights(config)
end

function theme.colorscheme()
  if vim.version().minor < 8 then
    vim.notify(
      'Neovim 0.8+ is required for butbicket colorscheme',
      vim.log.levels.ERROR,
      { title = 'Min Theme' }
    )
    return
  end

  vim.api.nvim_command 'hi clear'
  if vim.fn.exists 'syntax_on' then
    vim.api.nvim_command 'syntax reset'
  end

  vim.g.VM_theme_set_by_colorscheme = true
  vim.o.termguicolors = true
  vim.g.colors_name = 'butbicket'

  set_terminal_colors()
  set_groups()
end

return theme
