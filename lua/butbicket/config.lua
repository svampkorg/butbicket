---@class butbicket.Italics
---@field comments boolean
---@field keywords boolean
---@field functions boolean
---@field strings boolean
---@field variables boolean
---@field variable_members boolean
---@field variable_parameters boolean
---@field bufferline boolean
---@field statements boolean

---Integration toggle table. `default` sets the fallback for every integration
---not named explicitly; individual names override it. An enabled integration
---still only emits its groups when the plugin is actually installed
---(auto-detect), so leaving everything on is safe.
---@class butbicket.Integrations
---@field default? boolean fallback for unlisted integrations (default `true`)
---@field [string] boolean per-integration opt-out (e.g. `cmp = false`)

---@class butbicket.Config
---@field theme "dark"|"light"
---@field transparent boolean
---@field italics butbicket.Italics
---@field integrations butbicket.Integrations
---@field overrides table|fun():table

local config = {
  ---@type butbicket.Config
  defaults = {
    theme = "dark",
    transparent = false,
    italics = {
      comments = true,
      keywords = true,
      functions = false,
      strings = false,
      variables = false,
      variable_members = false,
      variable_parameters = true,
      bufferline = false,
      statements = true,
    },
    integrations = {
      default = true,
    },
    overrides = {},
  },
}

setmetatable(config, { __index = config.defaults })

return config
