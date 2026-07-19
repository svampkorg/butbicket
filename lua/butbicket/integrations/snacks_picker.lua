local c = require("butbicket.colorscheme")

local M = {}

-- Snacks picker + dashboard. Most SnacksPicker* groups link to sensible
-- defaults already; this themes the high-visibility surfaces (borders, titles,
-- match, prompt, git status) to the butbicket palette.
function M.highlights()
  return {
    -- picker chrome
    SnacksPicker = { fg = c.mainText, bg = c.floatingWindowBackground },
    SnacksPickerBorder = { fg = c.floatBorder, bg = c.floatingWindowBackground },
    SnacksPickerTitle = {
      fg = c.editorBackground,
      bg = c.syntaxFunction,
      bold = true,
    },
    SnacksPickerInput = { bg = c.popupBackground },
    SnacksPickerInputBorder = { fg = c.floatBorder, bg = c.popupBackground },
    SnacksPickerInputSearch = { fg = c.syntaxKeyword },
    SnacksPickerPrompt = { fg = c.syntaxKeyword },
    SnacksPickerPreview = { bg = c.editorBackground },
    SnacksPickerPreviewBorder = { fg = c.floatBorder, bg = c.editorBackground },
    SnacksPickerList = { bg = c.floatingWindowBackground },
    SnacksPickerListCursorLine = { bg = c.cursorline },
    SnacksPickerPreviewCursorLine = { bg = c.cursorline },
    -- results
    SnacksPickerMatch = { fg = c.warningEmphasis, bold = true },
    SnacksPickerDir = { fg = c.commentText },
    SnacksPickerFile = { fg = c.mainText },
    SnacksPickerDirectory = { fg = c.linkText },
    SnacksPickerComment = { fg = c.commentText },
    SnacksPickerDimmed = { fg = c.inactiveText },
    -- git
    SnacksPickerGitStatusAdded = { fg = c.added_bright },
    SnacksPickerGitStatusStaged = { fg = c.successText },
    SnacksPickerGitStatusModified = { fg = c.changed_bright },
    SnacksPickerGitStatusDeleted = { fg = c.removed_bright },
    SnacksPickerGitStatusRenamed = { fg = c.warningText },
    SnacksPickerGitStatusUntracked = { fg = c.inactiveText },
    SnacksPickerGitBranchCurrent = { fg = c.successText, bold = true },
    -- dashboard
    SnacksDashboardNormal = { fg = c.mainText },
    SnacksDashboardDesc = { fg = c.linkText },
    SnacksDashboardIcon = { fg = c.warningEmphasis },
    SnacksDashboardKey = { fg = c.syntaxKeyword },
    SnacksDashboardTitle = { fg = c.syntaxFunction, bold = true },
    SnacksDashboardHeader = { fg = c.syntaxFunction },
    SnacksDashboardFooter = { fg = c.commentText },
    SnacksDashboardSpecial = { fg = c.specialKeyword },
    SnacksDashboardDir = { fg = c.commentText },
    SnacksDashboardFile = { fg = c.mainText },
  }
end

return M
