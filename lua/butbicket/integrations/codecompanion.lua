local c = require("butbicket.colorscheme")

local M = {}

function M.highlights()
  return {
    CodeCompanionChatHeader = { fg = c.syntaxFunction, bold = true },
    CodeCompanionChatSeparator = { fg = c.windowBorder },
    CodeCompanionChatTokens = { fg = c.commentText },
    CodeCompanionChatSubtext = { fg = c.commentText },
    CodeCompanionChatInfo = { fg = c.linkText },
    CodeCompanionChatWarn = { fg = c.warningText },
    CodeCompanionChatContext = { fg = c.specialKeyword },
    CodeCompanionChatAdapter = { fg = c.method },
    CodeCompanionChatModel = { fg = c.type },
    CodeCompanionChatFold = { fg = c.commentText, bg = c.menuOptionBackground },
    CodeCompanionChatToolSuccess = { fg = c.successText },
    CodeCompanionChatToolFailure = { fg = c.errorText },
    CodeCompanionChatToolInProgress = { fg = c.warningText },
    CodeCompanionChatToolPending = { fg = c.warningEmphasis },
    CodeCompanionVirtualText = { fg = c.commentText, italic = true },
    CodeCompanionTools = { fg = c.method },
    CodeCompanionToolsStarted = { fg = c.warningText },
    CodeCompanionToolsFinished = { fg = c.successText },
    CodeCompanionDiffAdd = { bg = c.added_dim },
    CodeCompanionDiffDelete = { bg = c.removed_dim },
    CodeCompanionDiffText = { bg = c.changed_dim },
  }
end

return M
