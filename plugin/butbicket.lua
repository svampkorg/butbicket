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
-- (whatever is in your setup{ flavour = … }), for BOTH backgrounds. A flavour is
-- per-background (`{ dark = …, light = … }`), so each variant is emitted with its
-- own recipe; a legacy flat flavour applies on its polarity and the other side is
-- canonical. Writes to the given dir, or a stable per-user data dir (stdpath
-- ("data")/butbicket/extras) that survives plugin updates — regenerated in place,
-- so anything you symlink to those files picks up the new colors. NOT the plugin's
-- own extras/, which stays git-tracked. Use it after tuning a flavour so your
-- terminal + bat match your editor.
vim.api.nvim_create_user_command("ButbicketExtras", function(o)
  local dir = (o.args ~= "" and vim.fn.fnamemodify(o.args, ":p"))
    or (vim.fn.stdpath("data") .. "/butbicket/extras")
  local ok, written = pcall(function()
    return require("butbicket.extras").generate({
      dir = dir, -- both dark + light variants (extras.generate default)
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
  -- generate() collects the palette via the bare colorscheme() function, which
  -- does `hi clear` + re-apply but never fires the ColorScheme event — so
  -- listeners (incline's refresh, user autocmds) go stale. Re-apply through the
  -- :colorscheme COMMAND to fire it natively, exactly like the playground on
  -- close.
  pcall(vim.cmd.colorscheme, vim.g.colors_name or "butbicket")
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
