local colorscheme = require 'butbicket.colorscheme'

local M = {}

function M.highlights()
  return {
    BlinkCmpDocBorder = {
      fg = colorscheme.windowBorder,
      bg = colorscheme.floatingWindowBackground,
    },
    BlinkCmpMenuBorder = {
      fg = colorscheme.windowBorder,
      bg = colorscheme.floatingWindowBackground,
    },
    BlinkCmpSignatureHelpBorder = {
      fg = colorscheme.windowBorder,
      bg = colorscheme.floatingWindowBackground,
    },
    BlinkCmpLabelDescription = {
      fg = colorscheme.windowBorder,
      bg = colorscheme.floatingWindowBackground,
    },
  }
end

return M
