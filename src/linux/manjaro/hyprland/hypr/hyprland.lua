---@module 'hl'

local theme = require("theme")

--###############
--## MONITORS ###
--###############
-- See https://wiki.hyprland.org/Configuring/Monitors/

hl.monitor({
	output = "",
	mode = "highres",
	position = "auto",
	scale = 1,
})
hl.monitor({
	output = "eDP-1",
	mode = "highres",
	position = "auto",
	scale = 1,
})
hl.monitor({
	output = "DP-1",
	mode = "modeline 571.75 3440 3712 4088 4736 1440 1443 1453 1510 -hsync +vsync",
	position = "0x0",
	scale = 1,
})

--##################
--## MY PROGRAMS ###
--##################
-- See https://wiki.hyprland.org/Configuring/Keywords/

local terminal = "kitty"
local fileManager = "dolphin"
local menu = "rofi -show drun"
local browser = "vivaldi"

--############################
--## ENVIRONMENT VARIABLES ###
--############################

-- See https://wiki.hyprland.org/Configuring/Environment-variables/
hl.env("HYPRCURSOR_SIZE", 16)
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRSHOT_DIR", os.getenv("HOME") .. "/Pictures/")

-- https://wiki.hyprland.org/Configuring/Variables/#general
hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 5,
		-- border
		border_size = 4,
		-- draggable borders
		resize_on_border = true,
		allow_tearing = false,
		layout = "dwindle",
		col = {
			active_border = theme.border,
			inactive_border = theme.fg_subtle,
		},
	},
})
hl.config({
	cursor = {
		no_hardware_cursors = true,
		-- fix for laggy cursor
	},
})

-- https://wiki.hyprland.org/Configuring/Variables/#decoration

hl.config({
	decoration = {
		rounding = 5,
		rounding_power = 2,
		-- Change transparency of focused and unfocused windows
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		shadow = {
			enabled = true,
			range = 6,
			color = theme.fg_subtle,
			color_inactive = theme.fg_subtle,
		},
		-- https://wiki.hyprland.org/Configuring/Variables/#blur
		blur = {
			enabled = true,
			size = 3,
			passes = 1,
			vibrancy = 0.1696,
		},
	},
})

-- https://wiki.hyprland.org/Configuring/Variables/#animations

hl.config({
	animations = {
		enabled = true,
		-- Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
	},
})
hl.curve("easeOutQuint", {
	type = "bezier",
	points = { { 0.23, 1 }, { 0.32, 1 } },
})
hl.curve("easeInOutCubic", {
	type = "bezier",
	points = { { 0.65, 0.05 }, { 0.36, 1 } },
})
hl.curve("linear", {
	type = "bezier",
	points = { { 0, 0 }, { 1, 1 } },
})
hl.curve("almostLinear", {
	type = "bezier",
	points = { { 0.5, 0.5 }, { 0.75, 1.0 } },
})
hl.curve("quick", {
	type = "bezier",
	points = { { 0.15, 0 }, { 0.1, 1 } },
})
hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

-- Ref https://wiki.hyprland.org/Configuring/Workspace-Rules/
hl.config({
	dwindle = {
		preserve_split = true,
	},
})

-- See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
hl.config({
	master = {
		new_status = "master",
	},
})

-- https://wiki.hyprland.org/Configuring/Variables/#misc
hl.config({
	misc = {
		force_default_wallpaper = 0,
		-- Set to 0 or 1 to disable the anime mascot wallpapers
		disable_hyprland_logo = true,
		-- If true disables the random hyprland logo / anime girl background. :(
	},
})

--############
--## INPUT ###
--############

-- https://wiki.hyprland.org/Configuring/Variables/#input

hl.config({
	input = {
		kb_layout = "us",
		kb_options = "caps:swapescape",
		follow_mouse = 1,
		force_no_accel = true,
		accel_profile = "flat",
		sensitivity = -0.3,
		touchpad = {
			natural_scroll = true,
		},
	},
})

-- Example per-device config
-- See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more

hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})

--##################
--## KEYBINDINGS ###
--##################

-- See https://wiki.hyprland.org/Configuring/Keywords/

local mainMod = "ALT"

hl.bind(mainMod .. " + " .. "Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "Return", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "Q", hl.dsp.window.close())
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "E", hl.dsp.exit())
hl.bind(mainMod .. " + " .. "E", hl.dsp.exec_cmd(fileManager))
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + " .. "T", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + " .. "h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + " .. "l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + " .. "k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + " .. "j", hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + S", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "h", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "l", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "k", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "j", hl.dsp.window.move({ direction = "down" }))
hl.bind(
	mainMod .. " + " .. "SHIFT + Control" .. " + " .. "h",
	hl.dsp.window.resize({ x = -30, y = 0, relative = true })
)
hl.bind(mainMod .. " + " .. "SHIFT + Control" .. " + " .. "l", hl.dsp.window.resize({ x = 30, y = 0, relative = true }))
hl.bind(
	mainMod .. " + " .. "SHIFT + Control" .. " + " .. "k",
	hl.dsp.window.resize({ x = 0, y = -30, relative = true })
)
hl.bind(mainMod .. " + " .. "SHIFT + Control" .. " + " .. "j", hl.dsp.window.resize({ x = 0, y = 30, relative = true }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "f", hl.dsp.window.fullscreen())

-- Focus workspaces
hl.bind(mainMod .. " + " .. 1, hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + " .. 2, hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + " .. 3, hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + " .. 4, hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + " .. 5, hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + " .. 6, hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + " .. 7, hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + " .. 8, hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + " .. 9, hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + " .. 0, hl.dsp.focus({ workspace = 10 }))

-- Move workspaces
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 1, hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 2, hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 3, hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 4, hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 5, hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 6, hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 7, hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 8, hl.dsp.window.move({ workspace = 8 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 9, hl.dsp.window.move({ workspace = 9 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 0, hl.dsp.window.move({ workspace = 10 }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + " .. "mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + " .. "mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

--#############################
--## WINDOWS AND WORKSPACES ###
--#############################

hl.workspace_rule({
	workspace = 1,
	monitor = "DP-1",
})
hl.workspace_rule({
	workspace = 2,
	monitor = "DP-1",
})
hl.workspace_rule({
	workspace = 3,
	monitor = "eDP-1",
})
hl.workspace_rule({
	workspace = 4,
	monitor = "eDP-1",
})

-- See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
-- See https://wiki.hyprland.org/Configuring/Workspace-Rules/ for workspace rules

-- Autostart
hl.on("hyprland.start", function()
	hl.exec_cmd("[workspace 1 silent] " .. terminal)
	hl.exec_cmd("[workspace 2 silent] " .. browser)
	hl.exec_cmd("hyprpanel")
	hl.exec_cmd('bash -c "' .. os.getenv("HOME") .. '/.config/hypr/random_wp.sh && hyprpaper"')
	hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 16")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
	hl.exec_cmd("systemctl --user start avahi-daemon.service")
	hl.exec_cmd("systemctl --user start geoclue")
end)
