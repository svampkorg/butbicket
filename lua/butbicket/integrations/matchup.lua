local c = require("butbicket.colorscheme")

local M = {}

-- vim-matchup is vimscript (detected via `vim.g.loaded_matchup`). MatchParen is
-- themed in the core groups; this adds matchup's extra word/off-screen groups.
function M.highlights()
  return {
    MatchParenCur = { bold = true },
    MatchWord = { fg = c.hotpink, underline = true },
    MatchWordCur = { underline = true },
  }
end

return M
