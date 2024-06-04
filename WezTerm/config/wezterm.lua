-- project homepage: https://wezfurlong.org/wezterm/

-- format with stylua (scoop install stylua)

-- Pull in the wezterm API
local wezterm = require("wezterm")
local shutil = require("shutil")
local act = wezterm.action

-- shutil.which('git.exe')

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.initial_cols = 180
config.initial_rows = 55

-- Never change window size on font size change
config.adjust_window_size_when_changing_font_size = false

-- Changing the color scheme:
-- config.color_scheme = 'Ir Black (Gogh)'
-- config.color_scheme = 'Nord (Gogh)'
-- config.color_scheme = 'niji'
-- config.color_scheme = 'Jellybeans (Gogh)'
-- config.color_scheme = 'Monokai (terminal.sexy)'
config.color_scheme = "Monokai Vivid"
config.color_scheme = "Catppuccin Mocha"
-- config.color_scheme = "Selenized Dark (Gogh)"

config.enable_scroll_bar = true

local launch_menu = {}
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	local user_home = wezterm.home_dir
	local program_files = os.getenv("ProgramFiles")
	local program_files_x86 = os.getenv("ProgramFiles(x86)")
	config.default_prog = { "cmd.exe", "/k", "%LBPROGRAMS%\\bin\\profile.cmd" }
	table.insert(launch_menu, {
		label = "PowerShell",
		args = { "powershell.exe", "-NoLogo" },
	})
	table.insert(launch_menu, {
		label = "PowerShell 7",
		args = { "pwsh.exe", "-NoLogo" },
	})
	table.insert(launch_menu, {
		label = "Profile",
		args = { "cmd.exe", "/k", "%LBPROGRAMS%\\bin\\profile.cmd" },
		cwd = user_home,
	})
	table.insert(launch_menu, {
		label = "CMD",
		args = { "cmd.exe" },
	})
	table.insert(launch_menu, {
		label = "Git Bash",
		args = { program_files .. "\\Git\\usr\\bin\\bash.exe", "-i", "-l" },
		cwd = user_home,
	})

	-- Find installed visual studio version(s) and add their compilation
	-- environment command prompts to the menu
	for _, year in ipairs({ "2022" }) do
		table.insert(launch_menu, {
			label = "x64 Native Tools VC " .. year,
			args = {
				"cmd.exe",
				"/k",
				"vcvars64.bat",
			},
			cwd = program_files .. "/Microsoft Visual Studio/" .. year .. "/Community/VC/Auxiliary/Build",
		})
	end
end

config.launch_menu = launch_menu

config.ssh_domains = {
	{
		name = "elara",
		remote_address = "elara.lan.lboulard.net",
		username = "lboulard",
		multiplexing = "None",
		default_prog = { "tmux", "a", "-t", "0" },
		ssh_option = {
			identityfile = wezterm.home_dir .. "/.ssh/id_ecdsa.pub",
		},
	},
	{
		name = "io",
		remote_address = "io.lan.lboulard.net",
		username = "root",
		multiplexing = "None",
		default_prog = { "tmux", "a", "-t", "0" },
		ssh_option = {
			identityfile = wezterm.home_dir .. "/.ssh/id_ecdsa.pub",
		},
	},
	{
		name = "lboulard.fr",
		remote_address = "lboulard.fr",
		username = "lboulard",
		multiplexing = "None",
		default_prog = { "tmux", "a", "-t", "0" },
		ssh_option = {
			identityfile = wezterm.home_dir .. "/.ssh/id_ecdsa.pub",
		},
	},
}

-- Change default font for terminal display
if false then
	-- config.font = wezterm.font("JetBrains Mono", { weight = "Regular" })
	config.font = wezterm.font("Cascadia Mono PL", { weight = "Regular" })
	config.font_size = 9.0
else
	config.font = wezterm.font("Iosevka Term", { weight = "Medium" })
	config.font_size = 10.0
end

-- Match Windows UI
config.window_frame = {
	-- The font used in the tab bar.
	-- Roboto Bold is the default; this font is bundled
	-- with wezterm.
	-- Whatever font is selected here, it will have the
	-- main font setting appended to it to pick up any
	-- fallback fonts you may have used there.
	font = wezterm.font({ family = "Segoe UI", weight = "Medium" }),

	-- The size of the font in the tab bar.
	-- Default to 10.0 on Windows but 12.0 on other systems
	-- font_size = 10.0,

	-- active_titlebar_bg = "#008333",
	-- inactive_titlebar_bg = "#333333",
}

config.colors = {
	-- The color of the scrollbar "thumb"; the portion that represents the current viewport
	scrollbar_thumb = "#229292",

	-- The color of the split lines between panes
	split = "#a4a444",
}

config.window_padding = {
	left = "1cell",
	right = "9pt",
	top = "0.5cell",
	bottom = "0.25cell",
}

-- Too fancy ?
if false then
	config.window_background_gradient = {
		colors = {
			"#050505",
			"#313131",
		},
		noise = 64,
		-- preset = "BrBg",
		orientation = {
			Radial = {
				-- Specifies the x coordinate of the center of the circle,
				-- in the range 0.0 through 1.0.  The default is 0.5 which
				-- is centered in the X dimension.
				cx = 0.85,

				-- Specifies the y coordinate of the center of the circle,
				-- in the range 0.0 through 1.0.  The default is 0.5 which
				-- is centered in the Y dimension.
				cy = 0.85,

				-- Specifies the radius of the notional circle.
				-- The default is 0.5, which combined with the default cx
				-- and cy values places the circle in the center of the
				-- window, with the edges touching the window edges.
				-- Values larger than 1 are possible.
				radius = 1.20,
			},
		},
		interpolation = "CatmullRom",
		blend = "Oklab",
	}
end

-- config.window_background_opacity = 0.98

config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

config.mouse_bindings = {
	-- I am too used to paste on right click
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = act.PasteFrom("PrimarySelection"),
	},

	--  make CTRL-Click open hyperlinks
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = act.OpenLinkAtMouseCursor,
	},
	-- NOTE that binding only the 'Up' event can give unexpected behaviors.
	-- Read more below on the gotcha of binding an 'Up' event only.
}

-- add shortcut to rotate pan
config.keys = {
  {
	  key = 'o',
	  mods = 'CTRL|SHIFT|ALT',
	  action = act.RotatePanes 'Clockwise'
  },
}

-- and finally, return the configuration to wezterm
return config
