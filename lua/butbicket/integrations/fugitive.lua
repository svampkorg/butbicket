local c = require("butbicket.colorscheme")

local M = {}

-- vim-fugitive is a vimscript plugin (no requireable module); the registry
-- detects it via a predicate on its runtime function.
function M.highlights()
  return {
    fugitiveHeader = { fg = c.syntaxKeyword, bold = true },
    fugitiveHeading = { fg = c.syntaxFunction, bold = true },
    fugitiveHelpHeader = { fg = c.syntaxKeyword },
    fugitiveHelpTag = { fg = c.accentEmphasis },
    fugitiveHash = { fg = c.commentText },
    fugitiveCount = { fg = c.number },
    diffAdded = { fg = c.added_bright },
    diffRemoved = { fg = c.removed_bright },
  }
end

return M
