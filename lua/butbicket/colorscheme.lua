local config = require 'butbicket.config'

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
  standardWhite = '#ffffff',
  standardBlack = '#101214',
}

colorscheme.keyword = '#FD9891'
colorscheme.method = '#7EE2B8'
colorscheme.number = '#8FB8F6'
colorscheme.stringText = '#FBC828'
colorscheme.text = '#E7E7E8'
colorscheme.text_dark = '#D4D4D4'
colorscheme.parenthesis = '#CECFD2'
colorscheme.variable = '#B6B7BA'
colorscheme.annotation = '#96999E'
colorscheme.comment = '#AAABAF'
colorscheme.selected = '#89576E'
colorscheme.selected_inactive = '#464646'
colorscheme.type = '#CFE1FD'
colorscheme.blue = '#669CF0'
colorscheme.green = '#73A130'
colorscheme.red = '#E78178'
colorscheme.light_red = '#FEC195'
colorscheme.old_mustard = '#7B6215'
colorscheme.mustard = '#BA9420'
colorscheme.yellow = '#FBC828'
colorscheme.light_yellow = '#FFD700'
colorscheme.dark_purple = '#BF63F3'
colorscheme.purple = '#DA70D6'
colorscheme.base = '#101214'
colorscheme.base_1 = '#18191A'
colorscheme.base_2 = '#1F1F21'
colorscheme.base_3 = '#2D2D2D'
colorscheme.base_4 = '#303134'
colorscheme.separator = '#46474B'
colorscheme.cursorline = '#2B2B2E'
colorscheme.added = '#164B35'
colorscheme.removed = '#5D1F1A'
colorscheme.changed = '#183053'
colorscheme.added_dim = '#212A27'
colorscheme.removed_dim = '#2E2322'
colorscheme.changed_dim = '#20252B'
colorscheme.added_bright = '#1A5C41'
colorscheme.removed_bright = '#7B2922'
colorscheme.changed_bright = '#1F3E6B'
colorscheme.abyss = '#151A17'
colorscheme.dark_charcoal = '#262E2A'
colorscheme.charcoal = '#37423F'
colorscheme.dark_slate = '#495554'
colorscheme.slate = '#5B6768'
colorscheme.slate_gray = '#6E777B'
colorscheme.steel_gray = '#81888D'
colorscheme.hotpink = '#ff007c'
colorscheme.bright_green = '#30FF91'

if vim.o.background == 'light' then
  -- LIGHT
  colorscheme.editorBackground = config.transparent and 'none' or '#ffffff'
  colorscheme.sidebarBackground = '#dddddd'
  colorscheme.popupBackground = '#f6f6f6'
  colorscheme.floatingWindowBackground = '#e0e0e0'
  colorscheme.menuOptionBackground = '#ededed'

  colorscheme.mainText = '#616161'
  colorscheme.emphasisText = '#212121'
  colorscheme.commandText = '#333333'
  colorscheme.inactiveText = '#9e9e9e'
  colorscheme.disabledText = '#d0d0d0'
  colorscheme.lineNumberText = '#a1a1a1'
  colorscheme.selectedText = '#424242'
  colorscheme.inactiveSelectionText = '#757575'

  colorscheme.windowBorder = '#c2c3c5'
  colorscheme.focusedBorder = '#aaaaaa'
  colorscheme.emphasizedBorder = '#999999'

  colorscheme.syntaxFunction = '#6871ff'
  colorscheme.syntaxError = '#d6656a'
  colorscheme.syntaxKeyword = '#9966cc'
  colorscheme.errorText = '#d32f2f'
  colorscheme.warningText = '#f29718'
  colorscheme.linkText = '#1976d2'
  colorscheme.commentText = '#848484'
  colorscheme.stringText = '#dd8500'
  colorscheme.successText = '#22863a'
  colorscheme.warningEmphasis = '#cd9731'
  colorscheme.specialKeyword = '#800080'
  colorscheme.syntaxOperator = '#a1a1a1'
  colorscheme.foregroundEmphasis = '#000000'
  colorscheme.terminalGray = '#333333'
  colorscheme.syntaxNumber = colorscheme.number
else
  -- DARK
  colorscheme.editorBackground = config.transparent and 'none'
    or colorscheme.base
  colorscheme.sidebarBackground = colorscheme.base_2
  colorscheme.popupBackground = colorscheme.base_2
  colorscheme.floatingWindowBackground = colorscheme.base_1
  colorscheme.menuOptionBackground = colorscheme.base_3

  colorscheme.mainText = colorscheme.text_dark
  colorscheme.emphasisText = colorscheme.text
  colorscheme.commandText = colorscheme.variable
  colorscheme.inactiveText = colorscheme.slate
  colorscheme.disabledText = colorscheme.annotation
  colorscheme.lineNumberText = colorscheme.dark_slate
  colorscheme.selectedText = colorscheme.selected
  colorscheme.inactiveSelectionText = colorscheme.selected_inactive

  colorscheme.windowBorder = colorscheme.base_4
  colorscheme.focusedBorder = colorscheme.separator
  colorscheme.emphasizedBorder = colorscheme.blue

  colorscheme.syntaxError = colorscheme.red
  colorscheme.syntaxFunction = colorscheme.method
  colorscheme.warningText = colorscheme.mustard
  colorscheme.syntaxKeyword = colorscheme.keyword
  colorscheme.linkText = colorscheme.blue
  colorscheme.stringText = colorscheme.stringText
  colorscheme.warningEmphasis = colorscheme.yellow
  colorscheme.successText = colorscheme.green
  colorscheme.errorText = colorscheme.red
  colorscheme.specialKeyword = colorscheme.method
  colorscheme.commentText = colorscheme.slate
  colorscheme.syntaxOperator = colorscheme.parenthesis
  colorscheme.foregroundEmphasis = colorscheme.type
  colorscheme.syntaxNumber = colorscheme.number
  colorscheme.terminalGray = colorscheme.base
end
return colorscheme
