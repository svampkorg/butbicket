local c = require("butbicket.colorscheme")

local M = {}

function M.highlights()
  return {
    NeoTreeGitAdded = { fg = c.added_bright },
    NeoTreeGitConflict = { fg = c.errorText },
    NeoTreeGitDeleted = { fg = c.removed_bright },
    NeoTreeGitIgnored = { fg = c.slate_gray },
    NeoTreeGitModified = { fg = c.warningText }, -- unstaged
    NeoTreeGitStaged = { fg = c.successText },
    NeoTreeGitRenamed = { fg = c.warningText },
    NeoTreeGitUntracked = { fg = c.slate_gray },
  }
end

return M
