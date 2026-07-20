-- Generate terminal theme files from the butbicket palette.
--
-- Usage:
--   nvim -l scripts/gen-terminals.lua           # all targets, both variants
--   nvim -l scripts/gen-terminals.lua dark      # all targets, one variant
--   nvim -l scripts/gen-terminals.lua dark kitty # one variant, one target
--
-- Writes the repo's committed extras/ (canonical palette, no flavour). The
-- emitters live in lua/butbicket/extras.lua so the `:ButbicketExtras` command
-- can reuse them to generate flavour-matched files for end users.

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local extras = require("butbicket.extras")

extras.generate({
  dir = "extras",
  variants = arg[1] and { arg[1] } or nil,
  targets = arg[2] and { arg[2] } or nil,
  on_write = function(path)
    print("wrote " .. path)
  end,
})
