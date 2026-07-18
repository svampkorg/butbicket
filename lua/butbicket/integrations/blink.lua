local colorscheme = require 'butbicket.colorscheme'

local M = {}

function M.highlights()
  return {
    BlinkCmpDocBorder = {
      fg = colorscheme.floatBorder,
      bg = colorscheme.floatingWindowBackground,
    },
    BlinkCmpMenuBorder = {
      fg = colorscheme.floatBorder,
      bg = colorscheme.floatingWindowBackground,
    },
    BlinkCmpSignatureHelpBorder = {
      fg = colorscheme.floatBorder,
      bg = colorscheme.floatingWindowBackground,
    },
    BlinkCmpLabelDescription = {
      fg = colorscheme.floatBorder,
      bg = colorscheme.floatingWindowBackground,
    },
  }
end

return M
