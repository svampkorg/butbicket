local c = require("butbicket.colorscheme")

local M = {}

function M.highlights()
  return {
    NvimTreeNormal = { fg = c.mainText, bg = c.sidebarBackground },
    NvimTreeNormalNC = { fg = c.mainText, bg = c.sidebarBackground },
    NvimTreeEndOfBuffer = { fg = c.sidebarBackground, bg = c.sidebarBackground },
    NvimTreeWinSeparator = { fg = c.windowBorder, bg = c.sidebarBackground },
    NvimTreeCursorLine = { bg = c.cursorline },
    NvimTreeRootFolder = { fg = c.syntaxKeyword, bold = true },
    NvimTreeFolderName = { fg = c.linkText },
    NvimTreeOpenedFolderName = { fg = c.linkText, bold = true },
    NvimTreeEmptyFolderName = { fg = c.inactiveText },
    NvimTreeFolderIcon = { fg = c.linkText },
    NvimTreeFolderArrowClosed = { fg = c.syntaxOperator },
    NvimTreeFolderArrowOpen = { fg = c.syntaxOperator },
    NvimTreeOpenedFile = { fg = c.emphasisText, bold = true },
    NvimTreeModifiedFile = { fg = c.warningText },
    NvimTreeSpecialFile = { fg = c.accentEmphasis, underline = true },
    NvimTreeExecFile = { fg = c.successText },
    NvimTreeImageFile = { fg = c.specialKeyword },
    NvimTreeSymlink = { fg = c.linkText, italic = true },
    NvimTreeIndentMarker = { fg = c.lineNumberText },
    NvimTreeWindowPicker = {
      fg = c.editorBackground,
      bg = c.syntaxKeyword,
      bold = true,
    },
    NvimTreeGitDirty = { fg = c.mustard },
    NvimTreeGitNew = { fg = c.added_bright },
    NvimTreeGitStaged = { fg = c.successText },
    NvimTreeGitDeleted = { fg = c.removed_bright },
    NvimTreeGitMerge = { fg = c.errorText },
    NvimTreeGitRenamed = { fg = c.warningText },
    NvimTreeGitIgnored = { fg = c.inactiveText },
  }
end

return M
