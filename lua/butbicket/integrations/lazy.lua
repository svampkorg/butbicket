local c = require("butbicket.colorscheme")

local M = {}

function M.highlights()
  return {
    LazyLocal = { fg = c.successText },
    LazySpecial = { fg = c.blue },
  }
end

return M
