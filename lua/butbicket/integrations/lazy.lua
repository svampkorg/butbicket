local c = require("butbicket.colorscheme")

local M = {}

function M.highlights()
  return {
    LazyLocal = { fg = c.green },
    LazySpecial = { fg = c.blue },
  }
end

return M
