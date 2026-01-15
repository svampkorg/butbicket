local colorscheme = require 'butbicket.colorscheme'
local utils = require 'butbicket.utils'

local M = {}

function M.highlights()
  return {
    -- Main elements
    NeogitHunkHeader = { fg = colorscheme.mainText, bg = colorscheme.base_2 },
    NeogitHunkHeaderHighlight = { fg = colorscheme.emphasisText, bg = colorscheme.base_2, bold = true },
    NeogitDiffContext = { bg = colorscheme.base_1 },
    NeogitDiffContextHighlight = { bg = colorscheme.base_2 },

    -- Additions
    NeogitDiffAdd = { bg = colorscheme.added_dim },
    NeogitDiffAddHighlight = { bg = colorscheme.added },
    NeogitHunkHeaderPart = { fg = colorscheme.added, bg = colorscheme.base_2 },

    -- Deletions
    NeogitDiffDelete = { bg = colorscheme.removed_dim },
    NeogitDiffDeleteHighlight = { bg = colorscheme.removed },
    NeogitHunkHeaderPartDown = { fg = colorscheme.removed, bg = colorscheme.base_2 },

    -- Branch / Remote
    NeogitRemote = { fg = colorscheme.syntaxFunction },
    NeogitBranch = { fg = colorscheme.syntaxKeyword, bold = true },
    NeogitObjectId = { fg = colorscheme.commentText },

    -- Status Section Headers
    NeogitSectionHeader = { fg = colorscheme.syntaxFunction, bold = true },
    NeogitSectionHeaderCount = { fg = colorscheme.mainText },

    -- Popups
    NeogitPopupSectionTitle = { fg = colorscheme.syntaxFunction },
    NeogitPopupBranchName = { fg = colorscheme.syntaxKeyword },
    NeogitPopupActionKey = { fg = colorscheme.method },
    NeogitPopupSwitchKey = { fg = colorscheme.method },

    -- Notifications
    NeogitNotificationInfo = { fg = colorscheme.syntaxFunction },
    NeogitNotificationWarning = { fg = colorscheme.warningText },
    NeogitNotificationError = { fg = colorscheme.errorText },
  }
end

return M
