-- shutil module to help inquiries environment

local wezterm = require("wezterm")

local module = {}

-- This function is private to this module and is not visible
-- outside.
local function private_helper()
  wezterm.log_error 'hello!'
end

function module.which(cmd)
	private_helper()
	return nil
end

return module
