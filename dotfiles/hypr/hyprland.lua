hl.plugin.load("/etc/hypr/plugins/libscrolloverview.so")

hl.monitor({ output = "DP-3", mode = "5120x2160@165", position = "0x0", scale = "1.25" })
hl.monitor({ output = "DP-2", mode = "5120x1440@119.999", position = "auto-up", scale = "1.25" })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" }) -- catch-all, keep last

hl.on("hyprland.start", function()
	hl.exec_cmd("noctalia")
end)

hl.env("XCURSOR_THEME", "macOS")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")

hl.config({
	general = {
		layout = "scrolling",
		gaps_in = 5,
		gaps_out = 10,
		border_size = 2,
		resize_on_border = true,
		allow_tearing = true,
	},



	scrolling = {
		column_width = 0.333,
		explicit_column_widths = "0.25, 0.333, 0.5, 0.667, 0.75, 1.0",
		fullscreen_on_one_column = false,
		focus_fit_method = 1,
		follow_focus = true,
		follow_min_visible = 0.4,
		wrap_focus = true,
		wrap_swapcol = true,
		direction = "right",
	},

	decoration = {
		rounding = 12,
		rounding_power = 2,
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		shadow = { enabled = true, range = 4, render_power = 3, color = "0xee1a1a1a" },

		blur = {
			enabled = true,
			size = 8,
			passes = 3,
			noise = 0.02,
			contrast = 1.0,
			brightness = 1.0,
			vibrancy = 0.25,
			popups = true,
		},
	},

	animations = { enabled = true },

	input = {
		kb_layout = "us",
		kb_options = "",
		follow_mouse = 1,
		sensitivity = 0,
		accel_profile = "flat",
		touchpad = { natural_scroll = false },
	},

	misc = {
		disable_hyprland_logo = true,
		force_default_wallpaper = 0,
		focus_on_activate = true,

	},

	cursor = {
		-- no_hardware_cursors = 1,
		default_monitor = "DP-3",
		warp_on_change_workspace = 1,
		warp_on_toggle_special = 1,
	},

	xwayland = { force_zero_scaling = true },

	binds = { window_direction_monitor_fallback = false },

	plugin = {
		scrolloverview = {
			layout = "vertical",
			scale = 0.5,
			workspace_gap = 40,
		},
	},
})

-- Animations
local anim = 0.9 -- 1.0 = upstream timings; lower = faster

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("easy", { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global", enabled = true, speed = 10 * anim, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39 * anim, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79 * anim, spring = "easy" })
hl.animation({
	leaf = "windowsIn",
	enabled = true,
	speed = 4.1 * anim,
	spring = "easy",
	style = "popin 87%",
})
hl.animation({
	leaf = "windowsOut",
	enabled = true,
	speed = 1.49 * anim,
	bezier = "linear",
	style = "popin 87%",
})
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73 * anim, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46 * anim, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03 * anim, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81 * anim, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4 * anim, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5 * anim, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79 * anim, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39 * anim, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94 * anim, bezier = "almostLinear", style = "slidevert" })
-- hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94 * anim, bezier = "almostLinear", style = "fade" })
-- hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21 * anim, bezier = "almostLinear", style = "fade" })
-- hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94 * anim, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 7, bezier = "easeOutQuint", style = "slidevert" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 7, bezier = "easeOutQuint", style = "slidevert" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 7, bezier = "easeOutQuint", style = "slidevert" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7 * anim, bezier = "quick" })

------------------------------------------------------------------------------
-- 6. Rules   (wiki: Configuring → Core → Rules: Window / Layer / Workspace rules)
--    hl.window_rule({ name?, match = { prop = value }, effect = value })
--    Find class/title with `hyprctl clients` or `hyprctl activewindow`.
------------------------------------------------------------------------------
hl.layer_rule({
	name = "noctalia",
	match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$" },
	no_anim = true,
	ignore_alpha = 0.2,
	blur = true,
	blur_popups = true,
})
hl.window_rule({
	name = "noctalia-settings",
	match = { class = "dev.noctalia.Noctalia" },
	float = true,
	size = { 1080, 920 },
})

-- Two rules the upstream example ships and recommends
hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({
	name = "fix-xwayland-drags",
	match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
	no_focus = true,
})

-- Scrolling: per-app starting column width (Scrolling-Layout page → Window rules)
hl.window_rule({ name = "browser-width", match = { class = "^zen.*$" }, scrolling_width = 0.5 })
hl.window_rule({ name = "termiinal-widht", match = { class = "^kitty.*$" }, scrolling_width = 0.25 })

-- Binds
require("binds")

-- For Noctalia Color templates
require("noctalia").apply_theme()
