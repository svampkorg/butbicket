local c = require("butbicket.colorscheme")

local M = {}

-- todo-comments builds TodoFg<KW>/TodoBg<KW>/TodoSign<KW> for each keyword from
-- its own `colors` option, so it may override these when its setup runs after
-- the colorscheme. Providing them still covers the load order where the scheme
-- wins and gives sensible defaults out of the box. Keywords + color slots match
-- todo-comments' defaults (FIX=error, TODO=info, HACK/WARN=warning, PERF, NOTE,
-- TEST).
local keywords = {
  FIX = c.errorText,
  TODO = c.linkText,
  HACK = c.warningText,
  WARN = c.warningText,
  PERF = c.specialKeyword,
  NOTE = c.successText,
  TEST = c.method,
}

function M.highlights()
  local groups = {}
  for name, color in pairs(keywords) do
    groups["TodoFg" .. name] = { fg = color }
    groups["TodoBg" .. name] =
      { fg = c.editorBackground, bg = color, bold = true }
    groups["TodoSign" .. name] = { fg = color }
  end
  return groups
end

return M
