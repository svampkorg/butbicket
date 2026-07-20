local c = require("butbicket.colorscheme")

local M = {}

function M.highlights()
  return {
    TelescopeNormal = { fg = c.mainText, bg = c.floatingWindowBackground },
    TelescopeBorder = { fg = c.floatBorder, bg = c.floatingWindowBackground },
    TelescopeResultsNormal = {
      fg = c.mainText,
      bg = c.floatingWindowBackground,
    },
    TelescopeResultsBorder = {
      fg = c.floatBorder,
      bg = c.floatingWindowBackground,
    },
    TelescopeResultsTitle = {
      fg = c.editorBackground,
      bg = c.accentEmphasis,
      bold = true,
    },
    TelescopePreviewNormal = { fg = c.mainText, bg = c.editorBackground },
    TelescopePreviewBorder = { fg = c.floatBorder, bg = c.editorBackground },
    TelescopePreviewTitle = {
      fg = c.editorBackground,
      bg = c.successText,
      bold = true,
    },
    TelescopePromptNormal = { fg = c.mainText, bg = c.popupBackground },
    TelescopePromptBorder = { fg = c.floatBorder, bg = c.popupBackground },
    TelescopePromptTitle = {
      fg = c.editorBackground,
      bg = c.syntaxFunction,
      bold = true,
    },
    TelescopePromptPrefix = { fg = c.syntaxKeyword },
    TelescopePromptCounter = { fg = c.commentText },
    TelescopeSelection = { fg = c.emphasisText, bg = c.cursorline },
    TelescopeSelectionCaret = { fg = c.syntaxKeyword, bg = c.cursorline },
    TelescopeMultiSelection = { fg = c.warningText },
    TelescopeMultiIcon = { fg = c.syntaxFunction },
    TelescopeMatching = { fg = c.accentEmphasis, bold = true },
    TelescopeResultsComment = { fg = c.commentText },
    TelescopeResultsDiffAdd = { fg = c.added_bright },
    TelescopeResultsDiffChange = { fg = c.changed_bright },
    TelescopeResultsDiffDelete = { fg = c.removed_bright },
  }
end

return M
