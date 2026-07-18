local colorscheme = require("butbicket.colorscheme")
-- local utils = require 'butbicket.utils'

local M = {}

function M.highlights()
  return {
    FlashMatch = { fg = colorscheme.hotpink },
    FlashCurrent = {
      fg = colorscheme.bright_green,
      bg = colorscheme.old_mustard,
    },
    FlashLabel = { fg = colorscheme.bright_green },
  }
end

return M
