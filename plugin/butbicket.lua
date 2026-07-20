-- Command + mapping surface for butbicket. Sourced once at startup; the heavy
-- module (the flavour playground UI) is only required when actually invoked, so
-- this stays side-effect free beyond registering the entry points.
if vim.g.loaded_butbicket then
  return
end
vim.g.loaded_butbicket = true

vim.api.nvim_create_user_command("ButbicketFlavour", function()
  require("butbicket.playground").open()
end, { desc = "Open the butbicket flavour playground" })

-- Generate terminal / bat / Claude Code theme files matching the ACTIVE flavour
-- (whatever is in your setup{ flavour = … }), for the current background. Writes
-- to the given dir, or ./butbicket-extras. Use it after tuning a flavour so your
-- terminal + bat match your editor.
vim.api.nvim_create_user_command("ButbicketExtras", function(o)
  local dir = (o.args ~= "" and vim.fn.fnamemodify(o.args, ":p"))
    or (vim.fn.getcwd() .. "/butbicket-extras")
  local ok, written = pcall(function()
    return require("butbicket.extras").generate({
      dir = dir,
      variants = { vim.o.background }, -- the base the active flavour targets
    })
  end)
  if not ok then
    vim.notify(
      "butbicket: extras generation failed: " .. tostring(written),
      vim.log.levels.ERROR,
      { title = "butbicket" }
    )
    return
  end
  vim.notify(
    ("butbicket: wrote %d files to %s"):format(#written, dir),
    vim.log.levels.INFO,
    { title = "butbicket" }
  )
end, {
  nargs = "?",
  complete = "dir",
  desc = "Generate terminal/bat/Claude Code themes from the active flavour",
})

-- Opt-in mapping only (no default keymap, per Neovim plugin conventions):
--   vim.keymap.set("n", "<leader>bf", "<Plug>(butbicket-flavour)")
vim.keymap.set("n", "<Plug>(butbicket-flavour)", function()
  require("butbicket.playground").open()
end, { desc = "butbicket: flavour playground" })
