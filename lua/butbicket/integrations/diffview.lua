local c = require("butbicket.colorscheme")

local M = {}

function M.highlights()
  return {
    DiffviewNormal = { fg = c.mainText, bg = c.sidebarBackground },
    DiffviewDim = { fg = c.inactiveText },
    DiffviewFolderName = { fg = c.linkText },
    DiffviewFolderSign = { fg = c.linkText },
    DiffviewReference = { fg = c.warningEmphasis },
    DiffviewHash = { fg = c.commentText },
    DiffviewFilePanelTitle = { fg = c.syntaxKeyword, bold = true },
    DiffviewFilePanelCounter = { fg = c.warningEmphasis, bold = true },
    DiffviewFilePanelFileName = { fg = c.mainText },
    DiffviewFilePanelPath = { fg = c.commentText },
    DiffviewFilePanelRootPath = { fg = c.commentText, bold = true },
    DiffviewFilePanelInsertions = { fg = c.added_bright },
    DiffviewFilePanelDeletions = { fg = c.removed_bright },
    DiffviewFilePanelConflicts = { fg = c.errorText },
    DiffviewFilePanelSelected = { fg = c.emphasisText, bold = true },
    DiffviewStatusAdded = { fg = c.added_bright },
    DiffviewStatusModified = { fg = c.changed_bright },
    DiffviewStatusDeleted = { fg = c.removed_bright },
    DiffviewStatusRenamed = { fg = c.warningText },
    DiffviewStatusCopied = { fg = c.linkText },
    DiffviewStatusUnmerged = { fg = c.errorText },
    DiffviewStatusUnknown = { fg = c.inactiveText },
    DiffviewStatusIgnored = { fg = c.inactiveText },
    DiffviewStatusBroken = { fg = c.errorText },
    DiffviewStatusTypeChanged = { fg = c.changed_bright },
  }
end

return M
