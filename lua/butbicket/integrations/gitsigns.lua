local c = require("butbicket.colorscheme")

local M = {}

function M.highlights()
  return {
    GitSignsAdd = { fg = c.added_bright },
    GitSignsChange = { fg = c.changed_bright },
    GitSignsDelete = { fg = c.removed_bright },
    GitSignsAddNr = { fg = c.added_bright },
    GitSignsChangeNr = { fg = c.changed_bright },
    GitSignsDeleteNr = { fg = c.removed_bright },
    GitSignsAddLn = { bg = c.added_dim },
    GitSignsChangeLn = { bg = c.changed_dim },
    GitSignsDeleteLn = { bg = c.removed_dim },
    GitSignsAddCul = { fg = c.added_bright, bold = true },
    GitSignsChangeCul = { fg = c.changed_bright, bold = true },
    GitSignsDeleteCul = { fg = c.removed_bright, bold = true },
    GitSignsCurrentLineBlame = { fg = c.commentText, italic = true },
    GitSignsAddPreview = { bg = c.added_dim },
    GitSignsChangePreview = { bg = c.changed_dim },
    GitSignsDeletePreview = { bg = c.removed_dim },
    GitSignsAddInline = { fg = c.added_bright },
    GitSignsChangeInline = { fg = c.changed_bright },
    GitSignsDeleteInline = { fg = c.removed_bright },
  }
end

return M
