local config = {
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
		overrides = {},
	},
}

setmetatable(config, { __index = config.defaults })

return config
