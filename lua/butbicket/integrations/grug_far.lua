local c = require("butbicket.colorscheme")

local M = {}

function M.highlights()
  return {
    GrugFarHelpHeader = { fg = c.syntaxKeyword, bold = true },
    GrugFarHelpHeaderKey = { fg = c.warningEmphasis },
    GrugFarHelpWinHeader = { fg = c.syntaxFunction, bold = true },
    GrugFarHelpWinActionKey = { fg = c.warningEmphasis },
    GrugFarHelpWinActionPrefix = { fg = c.syntaxKeyword },
    GrugFarHelpWinActionText = { fg = c.mainText },
    GrugFarHelpWinActionDescription = { fg = c.commentText },
    GrugFarInputLabel = { fg = c.syntaxKeyword, bold = true },
    GrugFarInputPlaceholder = { fg = c.inactiveText },
    GrugFarResultsHeader = { fg = c.syntaxFunction, bold = true },
    GrugFarResultsCmdHeader = { fg = c.syntaxKeyword },
    GrugFarResultsStats = { fg = c.commentText },
    GrugFarResultsActionMessage = { fg = c.warningText },
    GrugFarResultsPath = { fg = c.linkText },
    GrugFarResultsLineNr = { fg = c.lineNumberText },
    GrugFarResultsColumnNr = { fg = c.lineNumberText },
    GrugFarResultsNumberLabel = { fg = c.number },
    GrugFarResultsCursorLineNo = { fg = c.lineNumberText, bold = true },
    GrugFarResultsMatch = { fg = c.editorBackground, bg = c.warningEmphasis },
    GrugFarResultsMatchAdded = { fg = c.added_bright },
    GrugFarResultsMatchRemoved = { fg = c.removed_bright },
    GrugFarResultsAddIndicator = { fg = c.added_bright },
    GrugFarResultsRemoveIndicator = { fg = c.removed_bright },
    GrugFarResultsChangeIndicator = { fg = c.changed_bright },
    GrugFarCurrentMatch = { bg = c.cursorline },
  }
end

return M
