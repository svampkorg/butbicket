-- bat / Sublime .tmTheme for CODE SYNTAX highlighting. Claude Code renders code
-- via bat, reading the theme name from CLAUDE_CODE_SYNTAX_HIGHLIGHT (or
-- BAT_THEME). Install into `$(bat --config-dir)/themes/`, run `bat cache
-- --build`, then set that env var to the theme name.
--
-- Takes the collected palette table `t` (see extras/init.lua `collect`) and
-- returns `{ ext, body }`.

local M = {}

local function join(t, sep)
  return table.concat(t, sep)
end

M.bat = function(t)
  local function settings(kvs)
    local out = {}
    for _, kv in ipairs(kvs) do
      out[#out + 1] = ("        <key>%s</key>\n        <string>%s</string>"):format(
        kv[1],
        kv[2]
      )
    end
    return join(out, "\n")
  end

  local function entry(scope, kvs)
    local head = scope
        and ("      <key>scope</key>\n      <string>%s</string>\n"):format(
          scope
        )
      or ""
    return table.concat({
      "    <dict>",
      head .. "      <key>settings</key>",
      "      <dict>",
      settings(kvs),
      "      </dict>",
      "    </dict>",
    }, "\n")
  end

  -- scope -> color (+ optional fontStyle)
  local scopes = {
    { "comment", t.comment, "italic" },
    { "string", t.string },
    { "constant.numeric", t.number },
    { "constant.language", t.boolean },
    { "constant.character.escape", t.string },
    { "keyword, storage, storage.type, keyword.control", t.keyword, "italic" },
    {
      "keyword.operator, punctuation.separator, punctuation.terminator",
      t.operator,
    },
    {
      "entity.name.function, support.function, meta.function-call",
      t.func,
    },
    { "variable, variable.other, meta.variable", t.variable },
    { "variable.parameter", t.parameter },
    {
      "entity.name.type, entity.name.class, support.type, support.class",
      t.type,
    },
    { "entity.name.tag", t.tag },
    { "entity.other.attribute-name", t.attribute },
    -- NOTE: no broad `punctuation.definition` rule — it out-specifies `comment`
    -- and `string` (whose delimiters inherit punctuation.definition.*) and would
    -- recolour them. Brackets fall to foreground, matching the Neovim look.
    { "invalid, invalid.illegal", t.error },
  }

  local entries = {
    entry(nil, {
      { "background", t.bg },
      { "foreground", t.fg },
      { "caret", t.cursor },
      { "selection", t.sel_bg },
      { "lineHighlight", t.line_bg },
    }),
  }
  for _, sc in ipairs(scopes) do
    local kvs = { { "foreground", sc[2] } }
    if sc[3] then
      kvs[#kvs + 1] = { "fontStyle", sc[3] }
    end
    entries[#entries + 1] = entry(sc[1], kvs)
  end

  local body = table.concat({
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">',
    '<plist version="1.0">',
    "<dict>",
    "  <key>name</key>",
    ("  <string>%s</string>"):format(t.name),
    "  <key>settings</key>",
    "  <array>",
    join(entries, "\n"),
    "  </array>",
    "</dict>",
    "</plist>",
    "",
  }, "\n")
  return { ext = ".tmTheme", body = body }
end

return M
