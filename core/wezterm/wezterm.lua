-- Pull in the wezterm API
local wezterm = require("wezterm")
local mux = wezterm.mux

-- This will hold the configuration.
local config = wezterm.config_builder()
local action = wezterm.action

config = {
	color_scheme = "Fairyfloss",
	window_decorations = "RESIZE",
	automatically_reload_config = true,
	hide_tab_bar_if_only_one_tab = true,
	font = wezterm.font("JetBrains Mono"),
	font_size = 14,
	window_padding = {
		top = 0,
		bottom = 0,
		left = 3,
		right = 3,
	},
	background = {
		{
			source = {
				Color = "#282c35",
			},
			width = "100%",
			height = "100%",
			opacity = 0.55,
		},
	},
	leader = { key = "b", mods = "CTRL", timeout_milliseconds = 2000 },
	keys = {
		{
			key = "c",
			mods = "LEADER",
			action = action.SpawnTab("CurrentPaneDomain"),
		},

		{
			key = "l",
			mods = "LEADER",
			action = action.ActivateTabRelative(1),
		},
		{
			key = "h",
			mods = "LEADER",
			action = action.ActivateTabRelative(-1),
		},
		{
			key = "q",
			mods = "LEADER",
			action = action.CloseCurrentPane({ confirm = false }),
		},
	},
}

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	config.default_prog = { "pwsh", "-NoLogo" }
else
	config.default_prog = { "/bin/zsh", "-1" }
end

for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = action.ActivateTab(i - 1),
	})
end

return config
