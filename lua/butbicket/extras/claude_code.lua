-- Claude Code custom theme (~/.claude/themes/<name>.json). Controls UI chrome
-- only — diffs, borders, status, accent — NOT code syntax highlighting (that is
-- bat's job; see extras/bat.lua). Unknown/invalid override keys are ignored.
--
-- Takes the collected palette table `t` (see extras/init.lua `collect`) and
-- returns `{ ext, body }`.

local M = {}

local function join(t, sep)
  return table.concat(t, sep)
end

M["claude-code"] = function(t)
  local overrides = {
    { "claude", t.accent },
    { "text", t.fg },
    { "inverseText", t.bg },
    { "inactive", t.inactive },
    { "subtle", t.border },
    { "suggestion", t.comment },
    { "permission", t.emph_border },
    { "planMode", t.purple },
    { "autoAccept", t.success },
    { "bashBorder", t.operator },
    { "promptBorder", t.focus_border },
    { "success", t.success },
    { "error", t.error },
    { "warning", t.warning },
    { "diffAdded", t.added },
    { "diffRemoved", t.removed },
    { "diffAddedDimmed", t.added_dim },
    { "diffRemovedDimmed", t.removed_dim },
    { "diffAddedWord", t.added_word },
    { "diffRemovedWord", t.removed_word },
  }
  local lines = {}
  for i, kv in ipairs(overrides) do
    lines[i] = ('    "%s": "%s"%s'):format(
      kv[1],
      kv[2],
      i < #overrides and "," or ""
    )
  end
  local body = table.concat({
    "{",
    ('  "name": "%s",'):format(t.name),
    ('  "base": "%s",'):format(t.light and "light" or "dark"),
    '  "overrides": {',
    join(lines, "\n"),
    "  }",
    "}",
    "",
  }, "\n")
  return { ext = ".json", body = body }
end

return M
