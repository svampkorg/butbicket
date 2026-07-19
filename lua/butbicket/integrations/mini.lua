local c = require("butbicket.colorscheme")

local M = {}

-- mini.nvim family. Themes the high-visibility modules the palette maps cleanly
-- onto (files, pick, indentscope, hipatterns, icons, notify, statusline,
-- cursorword, tabline, trailspace, jump, starter). Groups for modules the user
-- does not use are harmless.
function M.highlights()
  return {
    -- mini.files
    MiniFilesNormal = { fg = c.mainText, bg = c.floatingWindowBackground },
    MiniFilesBorder = { fg = c.floatBorder, bg = c.floatingWindowBackground },
    MiniFilesBorderModified = {
      fg = c.warningText,
      bg = c.floatingWindowBackground,
    },
    MiniFilesCursorLine = { bg = c.cursorline },
    MiniFilesDirectory = { fg = c.linkText },
    MiniFilesFile = { fg = c.mainText },
    MiniFilesTitle = { fg = c.commentText },
    MiniFilesTitleFocused = { fg = c.syntaxKeyword, bold = true },

    -- mini.pick
    MiniPickNormal = { fg = c.mainText, bg = c.floatingWindowBackground },
    MiniPickBorder = { fg = c.floatBorder, bg = c.floatingWindowBackground },
    MiniPickBorderBusy = { fg = c.warningText, bg = c.floatingWindowBackground },
    MiniPickBorderText = { fg = c.syntaxKeyword },
    MiniPickHeader = { fg = c.syntaxFunction, bold = true },
    MiniPickPrompt = { fg = c.syntaxKeyword },
    MiniPickPromptPrefix = { fg = c.warningEmphasis },
    MiniPickMatchCurrent = { bg = c.cursorline },
    MiniPickMatchMarked = { fg = c.warningText },
    MiniPickMatchRanges = { fg = c.warningEmphasis, bold = true },
    MiniPickIconDirectory = { fg = c.linkText },

    -- mini.indentscope
    MiniIndentscopeSymbol = { fg = c.dark_purple },
    MiniIndentscopeSymbolOff = { fg = c.removed_bright },

    -- mini.hipatterns
    MiniHipatternsFixme = {
      fg = c.editorBackground,
      bg = c.errorText,
      bold = true,
    },
    MiniHipatternsHack = {
      fg = c.editorBackground,
      bg = c.warningText,
      bold = true,
    },
    MiniHipatternsTodo = {
      fg = c.editorBackground,
      bg = c.linkText,
      bold = true,
    },
    MiniHipatternsNote = {
      fg = c.editorBackground,
      bg = c.successText,
      bold = true,
    },

    -- mini.icons
    MiniIconsAzure = { fg = c.blue },
    MiniIconsBlue = { fg = c.linkText },
    MiniIconsCyan = { fg = c.method },
    MiniIconsGreen = { fg = c.successText },
    MiniIconsGrey = { fg = c.commentText },
    MiniIconsOrange = { fg = c.warningText },
    MiniIconsPurple = { fg = c.specialKeyword },
    MiniIconsRed = { fg = c.errorText },
    MiniIconsYellow = { fg = c.warningEmphasis },

    -- mini.notify
    MiniNotifyNormal = { fg = c.mainText, bg = c.floatingWindowBackground },
    MiniNotifyBorder = { fg = c.floatBorder, bg = c.floatingWindowBackground },
    MiniNotifyTitle = { fg = c.syntaxKeyword, bold = true },

    -- mini.statusline
    MiniStatuslineModeNormal = {
      fg = c.editorBackground,
      bg = c.linkText,
      bold = true,
    },
    MiniStatuslineModeInsert = {
      fg = c.editorBackground,
      bg = c.successText,
      bold = true,
    },
    MiniStatuslineModeVisual = {
      fg = c.editorBackground,
      bg = c.specialKeyword,
      bold = true,
    },
    MiniStatuslineModeReplace = {
      fg = c.editorBackground,
      bg = c.errorText,
      bold = true,
    },
    MiniStatuslineModeCommand = {
      fg = c.editorBackground,
      bg = c.warningEmphasis,
      bold = true,
    },
    MiniStatuslineModeOther = {
      fg = c.editorBackground,
      bg = c.method,
      bold = true,
    },
    MiniStatuslineDevinfo = { fg = c.mainText, bg = c.menuOptionBackground },
    MiniStatuslineFileinfo = { fg = c.mainText, bg = c.menuOptionBackground },
    MiniStatuslineFilename = { fg = c.commentText, bg = c.sidebarBackground },
    MiniStatuslineInactive = { fg = c.inactiveText, bg = c.sidebarBackground },

    -- mini.cursorword
    MiniCursorword = { underline = true },
    MiniCursorwordCurrent = { underline = true },

    -- mini.tabline
    MiniTablineCurrent = {
      fg = c.emphasisText,
      bg = c.editorBackground,
      bold = true,
    },
    MiniTablineVisible = { fg = c.mainText, bg = c.sidebarBackground },
    MiniTablineHidden = { fg = c.inactiveText, bg = c.sidebarBackground },
    MiniTablineModifiedCurrent = {
      fg = c.warningText,
      bg = c.editorBackground,
      bold = true,
    },
    MiniTablineModifiedVisible = {
      fg = c.warningText,
      bg = c.sidebarBackground,
    },
    MiniTablineModifiedHidden = {
      fg = c.warningEmphasis,
      bg = c.sidebarBackground,
    },
    MiniTablineFill = { bg = c.windowBorder },
    MiniTablineTabpagesection = {
      fg = c.editorBackground,
      bg = c.syntaxFunction,
      bold = true,
    },

    -- mini.trailspace / jump / starter
    MiniTrailspace = { bg = c.errorText },
    MiniJump = { fg = c.hotpink, bold = true },
    MiniStarterHeader = { fg = c.syntaxFunction },
    MiniStarterFooter = { fg = c.commentText },
    MiniStarterItem = { fg = c.mainText },
    MiniStarterItemPrefix = { fg = c.warningEmphasis },
    MiniStarterSection = { fg = c.syntaxKeyword, bold = true },
    MiniStarterQuery = { fg = c.successText },
    MiniStarterCurrent = { bg = c.cursorline },
  }
end

return M
