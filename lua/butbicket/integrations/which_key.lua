local c = require("butbicket.colorscheme")

local M = {}

function M.highlights()
  return {
    WhichKey = { fg = c.syntaxFunction },
    WhichKeyGroup = { fg = c.linkText },
    WhichKeyDesc = { fg = c.mainText },
    WhichKeySeparator = { fg = c.commentText },
    WhichKeyValue = { fg = c.commentText },
    WhichKeyIcon = { fg = c.warningEmphasis },
    WhichKeyNormal = { bg = c.floatingWindowBackground },
    WhichKeyBorder = { fg = c.floatBorder, bg = c.floatingWindowBackground },
    WhichKeyTitle = {
      fg = c.editorBackground,
      bg = c.syntaxFunction,
      bold = true,
    },
    WhichKeyColorAzure = { fg = c.blue },
    WhichKeyColorBlue = { fg = c.linkText },
    WhichKeyColorCyan = { fg = c.method },
    WhichKeyColorGreen = { fg = c.successText },
    WhichKeyColorGrey = { fg = c.commentText },
    WhichKeyColorOrange = { fg = c.warningText },
    WhichKeyColorPurple = { fg = c.specialKeyword },
    WhichKeyColorRed = { fg = c.errorText },
    WhichKeyColorYellow = { fg = c.warningEmphasis },
  }
end

return M
