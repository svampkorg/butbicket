local colorscheme = require 'butbicket.colorscheme'
-- local utils = require 'butbicket.utils'

local M = {}

function M.highlights()
  return {
    HauntAnnotation = { fg = colorscheme.dark_purple },
  }
end

return M
