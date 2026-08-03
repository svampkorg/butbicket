-- `:checkhealth butbicket` entry point. Neovim auto-discovers this module and
-- calls `M.check()`. Read-only: it diagnoses the environment + user config and
-- reports which integrations are actually themed, so users can self-diagnose
-- before opening an issue.

local M = {}

-- vim.health.{start,ok,info,warn,error} landed in 0.10; earlier releases expose
-- the same reporters as `report_*`. butbicket supports Neovim 0.8+, so bind to
-- whichever the running version provides.
local h = vim.health
local start = h.start or h.report_start
local ok = h.ok or h.report_ok
local info = h.info or h.report_info
local warn = h.warn or h.report_warn
local err = h.error or h.report_error

---Describe the shape of `config.flavour` (false / single recipe / per-background)
---and flag obviously invalid values.
---@param flavour any
local function check_flavour(flavour)
  if flavour == false or flavour == nil then
    info("flavour: disabled (canonical palette)")
    return
  end
  if type(flavour) ~= "table" then
    err(
      ("config.flavour must be `false` or a table, got %s"):format(
        type(flavour)
      ),
      "see :h butbicket-flavour"
    )
    return
  end
  if flavour.dark ~= nil or flavour.light ~= nil then
    for _, side in ipairs({ "dark", "light" }) do
      if flavour[side] ~= nil and type(flavour[side]) ~= "table" then
        err(
          ("config.flavour.%s must be a table, got %s"):format(
            side,
            type(flavour[side])
          )
        )
        return
      end
    end
    local sides = {}
    if type(flavour.dark) == "table" then
      sides[#sides + 1] = "dark"
    end
    if type(flavour.light) == "table" then
      sides[#sides + 1] = "light"
    end
    ok(
      ("flavour: per-background recipe (%s); the other side stays canonical"):format(
        table.concat(sides, " + ")
      )
    )
  else
    ok(
      "flavour: single recipe (applies to the polarity its `background` lightness implies)"
    )
  end
end

function M.check()
  local config = require("butbicket.config")

  -- Environment ------------------------------------------------------------
  start("butbicket: environment")

  if vim.fn.has("nvim-0.8") == 1 then
    local v = vim.version and vim.version()
    ok(
      v
          and ("Neovim %d.%d.%d (>= 0.8 required)"):format(
            v.major,
            v.minor,
            v.patch
          )
        or "Neovim >= 0.8"
    )
  else
    err(
      "Neovim 0.8+ is required",
      "upgrade Neovim; butbicket refuses to apply on older versions"
    )
  end

  if vim.o.termguicolors then
    ok("'termguicolors' is set (24-bit color)")
  else
    warn(
      "'termguicolors' is off — butbicket needs 24-bit color to render",
      "butbicket sets it when applied; set `vim.o.termguicolors = true` early if a terminal-UI plugin reads it before then"
    )
  end

  if vim.g.colors_name == "butbicket" then
    ok(
      ("active colorscheme is butbicket (background=%s)"):format(
        vim.o.background
      )
    )
  else
    info(
      ("butbicket is not the active colorscheme (current: %s)"):format(
        vim.g.colors_name or "none"
      )
    )
  end

  -- Configuration ----------------------------------------------------------
  start("butbicket: configuration")

  if type(config.transparent) == "boolean" then
    ok(("transparent = %s"):format(config.transparent))
  else
    err(
      ("config.transparent must be a boolean, got %s"):format(
        type(config.transparent)
      )
    )
  end

  local ov = config.overrides
  if type(ov) == "table" or type(ov) == "function" then
    ok(("overrides: %s"):format(type(ov)))
  else
    err(
      ("config.overrides must be a table or function, got %s"):format(type(ov))
    )
  end

  if type(config.integrations) == "table" then
    ok(
      "integrations: table (default = "
        .. tostring(config.integrations.default ~= false)
        .. ")"
    )
  else
    err(
      ("config.integrations must be a table, got %s"):format(
        type(config.integrations)
      )
    )
  end

  check_flavour(config.flavour)

  -- Integrations -----------------------------------------------------------
  start("butbicket: integrations")

  local integrations = require("butbicket.integrations")
  local active, missing, disabled = {}, {}, {}
  for _, spec in ipairs(integrations.registry) do
    if not integrations.enabled(config.integrations, spec.name) then
      disabled[#disabled + 1] = spec.name
    elseif integrations.detectable(spec.detect) then
      active[#active + 1] = spec.name
    else
      missing[#missing + 1] = spec.name
    end
  end
  table.sort(active)
  table.sort(missing)
  table.sort(disabled)

  ok(
    ("%d integration(s) themed (enabled + installed): %s"):format(
      #active,
      #active > 0 and table.concat(active, ", ") or "none"
    )
  )
  if #missing > 0 then
    info(
      ("enabled but not installed, skipped: %s"):format(
        table.concat(missing, ", ")
      )
    )
  end
  if #disabled > 0 then
    info(("disabled in config: %s"):format(table.concat(disabled, ", ")))
  end
end

return M
