local colorscheme = require("butbicket.colorscheme")

local M = {}

function M.highlights()
  return {
    SnacksIndentScope = { fg = colorscheme.dark_purple },
  }
end

return M
