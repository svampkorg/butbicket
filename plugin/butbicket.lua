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

-- Opt-in mapping only (no default keymap, per Neovim plugin conventions):
--   vim.keymap.set("n", "<leader>bf", "<Plug>(butbicket-flavour)")
vim.keymap.set("n", "<Plug>(butbicket-flavour)", function()
  require("butbicket.playground").open()
end, { desc = "butbicket: flavour playground" })
