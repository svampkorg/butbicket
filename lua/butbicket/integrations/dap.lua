local c = require("butbicket.colorscheme")

local M = {}

-- Covers nvim-dap (sign groups), nvim-dap-virtual-text and nvim-dap-view.
-- Detection gates on nvim-dap; setting the view/virtual-text groups when those
-- companion plugins are absent is harmless.
function M.highlights()
  return {
    -- nvim-dap signs
    DapBreakpoint = { fg = c.errorText },
    DapBreakpointCondition = { fg = c.warningText },
    DapBreakpointRejected = { fg = c.inactiveText },
    DapLogPoint = { fg = c.linkText },
    DapStopped = { fg = c.accentEmphasis },
    -- nvim-dap-virtual-text
    NvimDapVirtualText = { fg = c.commentText, italic = true },
    NvimDapVirtualTextChanged = { fg = c.changed_bright, italic = true },
    NvimDapVirtualTextError = { fg = c.errorText, italic = true },
    NvimDapVirtualTextInfo = { fg = c.linkText, italic = true },
    -- nvim-dap-view
    NvimDapView = { fg = c.mainText, bg = c.sidebarBackground },
    NvimDapViewFrameCurrent = { fg = c.accentEmphasis, bold = true },
    NvimDapViewTab = { fg = c.mainText },
    NvimDapViewVirtualText = { fg = c.commentText },
    NvimDapViewVirtualTextUpdated = { fg = c.changed_bright },
    NvimDapViewWatchUpdated = { fg = c.changed_bright },
  }
end

return M
