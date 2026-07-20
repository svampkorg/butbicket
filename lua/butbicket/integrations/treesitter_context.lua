local c = require("butbicket.colorscheme")

local M = {}

function M.highlights()
  return {
    TreesitterContext = { bg = c.base_1 },
    TreesitterContextLineNumber = { bg = c.base_2, fg = c.separator },
    TreesitterContextBottom = {
      cterm = { underline = false },
      sp = c.base_3,
      underline = false,
    },
    TreesitterContextLineNumberBottom = { link = "TreesitterContextBottom" },
    TreesitterContextSeparator = { bg = c.base_2, fg = c.base_3 },
  }
end

return M
