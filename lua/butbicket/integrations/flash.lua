local colorscheme = require("butbicket.colorscheme")

local M = {}

function M.highlights()
  return {
    FlashMatch = { fg = colorscheme.hotpink },
    FlashCurrent = {
      fg = colorscheme.bright_green,
      bg = colorscheme.searchBase,
    },
    FlashLabel = { fg = colorscheme.bright_green },
  }
end

return M
