local colorscheme = require 'butbicket.colorscheme'
-- local utils = require 'butbicket.utils'

local M = {}

function M.highlights()
  return {
    FlashMatch = { fg = colorscheme.hotpink },
    FlashCurrent = { fg = colorscheme.hotpink, bg = colorscheme.old_mustard },
    FlashLabel = { fg = colorscheme.hotpink },
  }
end

return M
