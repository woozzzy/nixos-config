------------------------------------------------------------------------------
-- 1. Programs (plain Lua locals; referenced below)
------------------------------------------------------------------------------
local terminal = "kitty"
local browser = "zen"
local mainMod = "SUPER"
local nc = "noctalia msg " -- Noctalia v5 IPC prefix
local exec = hl.dsp.exec_cmd -- shorthand: exec("cmd") == hl.dsp.exec_cmd("cmd")

------------------------------------------------------------------------------
-- 2. Monitors   (wiki: Configuring → Core → Monitors;  `hyprctl monitors`)
------------------------------------------------------------------------------
hl.monitor({ output = "DP-3", mode = "5120x2160@165", position = "0x0", scale = "1.25" })
hl.monitor({ output = "DP-2", mode = "5120x1440@119.999", position = "auto-up", scale = "1.25" })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" }) -- catch-all, keep last

------------------------------------------------------------------------------
-- 3. Autostart   (wiki: Configuring → Core → Autostart;  Noctalia: "Autostart Noctalia")
------------------------------------------------------------------------------
hl.on("hyprland.start", function()
	hl.exec_cmd("noctalia") -- [noctalia] bar, launcher, notifications, OSD, wallpaper, lock/idle
end)

------------------------------------------------------------------------------
-- 4. Environment   (wiki: Configuring → Core → Environment variables;  Nvidia page)
--    hl.env sets variables for everything Hyprland launches — not for the compositor itself.
------------------------------------------------------------------------------
hl.env("XCURSOR_THEME", "macOS")
hl.env("XCURSOR_SIZE", "24") -- [default] as in the example config
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("LIBVA_DRIVER_NAME", "nvidia") -- [nvidia] VA-API through the NVIDIA driver
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia") -- [nvidia] GLX → NVIDIA's libGL
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto") -- [nvidia] Electron picks Wayland; NIXOS_OZONE_WL=1 is set Nix-side too

hl.env("GDK_BACKEND", "wayland,x11,*") -- GTK: Wayland first, X11 fallback   (env-vars page)
hl.env("QT_QPA_PLATFORM", "wayland;xcb") -- Qt:  Wayland first, X11 fallback   (env-vars page)
-- hl.env("SDL_VIDEODRIVER", "wayland")      -- env-vars page warns: breaks games bundling old SDL. Leave unset here.

------------------------------------------------------------------------------
-- 5. hl.config: look & feel, layout, input, misc
--    (wiki: Configuring → Core → Config options — the full option tables)
--    hl.config merges: several calls are fine; the last write to a key wins.
------------------------------------------------------------------------------
hl.config({
	general = {
		layout = "scrolling", -- [choice] default "dwindle"
		gaps_in = 5, -- [noctalia]
		gaps_out = 10, -- [noctalia]
		border_size = 2, -- [choice] default 1
		resize_on_border = true, -- [choice] default false — drag window edges/gaps to resize
		allow_tearing = false, -- [default] read Configuring → Tearing before enabling for games
	},

	-- Scrolling layout: windows sit on an endless horizontal tape of columns;
	-- the monitor is a viewport that scrolls along it. (Scrolling-Layout page)
	scrolling = {
		column_width = 0.5, -- [default] width of a new column, fraction of monitor
		explicit_column_widths = "0.25, 0.333, 0.5, 0.667, 0.75, 1.0", -- [default] presets cycled by `colresize +conf/-conf`
		fullscreen_on_one_column = false, -- [choice] default true: a lone column spans the screen. false = niri behaviour
		focus_fit_method = 1, -- [default] 0 = center the focused column, 1 = scroll just enough to fit
		follow_focus = true, -- [default] viewport follows keyboard focus
		follow_min_visible = 0.4, -- [default] …only if at least 40% of the window is already visible
		wrap_focus = true, -- [choice] default true wraps `focus l/r` at the ends; false = niri behaviour
		wrap_swapcol = true, -- [default]
		direction = "right", -- [default] new columns open to the right
	},

	decoration = {
		rounding = 12, -- [choice] Noctalia suggests 20, example uses 10
		rounding_power = 2, -- [default]
		active_opacity = 1.0, -- [default]
		inactive_opacity = 1.0, -- [default]
		shadow = { enabled = true, range = 4, render_power = 3, color = "0xee1a1a1a" }, -- [noctalia]
		-- blur = { enabled = true, size = 3, passes = 2, vibrancy = 0.1696 }, -- [noctalia] passes=2 is for its panels
		blur = {
			enabled = true,
			size = 8, -- default 8, Noctalia's suggestion 3 — the main "how frosted" knob
			passes = 3, -- default 1; bigger size needs more passes or it looks blocky (Blur table note)
			noise = 0.02, -- default 0.0117; a little grain reads as glass
			contrast = 1.0, -- default 0.8916
			brightness = 1.0, -- default 1; slightly darker glass
			vibrancy = 0.25, -- default 0.1696; saturates what's behind
			popups = true, -- default false; blur right-click menus too
		},
	},

	animations = { enabled = true }, -- [default]; per-element animations are set below

	input = { -- (Config options → Input)
		kb_layout = "us", -- [default]
		kb_options = "", -- e.g. "caps:swapescape" (Binds page → XKB options)
		follow_mouse = 1, -- [default] hovering focuses
		sensitivity = 0, -- [default] -1.0 … 1.0
		accel_profile = "flat", -- [choice] default "" (libinput adaptive); flat = no pointer acceleration
		touchpad = { natural_scroll = false }, -- [default]
	},

	misc = { -- (Config options → Misc)
		disable_hyprland_logo = true, -- [choice] default false; Noctalia draws the wallpaper
		force_default_wallpaper = 0, -- [choice] default -1 (random); 0 = no anime mascots
		focus_on_activate = true, -- [choice] default false; apps asking for focus (e.g. a browser opened from a link) get it
		-- vrr = 2,                       -- default 0; 2 = adaptive sync in fullscreen only. Set once the monitor is known
	},

	cursor = { -- (Config options → Cursor)
		-- no_hardware_cursors = 1,       -- default 2 (auto). Try 1 if the cursor flickers or vanishes on NVIDIA
		default_monitor = "DP-3",
		warp_on_change_workspace = 1,
		warp_on_toggle_special = 1,
	},

	xwayland = { force_zero_scaling = true }, -- [choice] default false; the documented fix for blurry XWayland on scaled outputs (XWayland page)

	binds = { window_direction_monitor_fallback = false },
})

-- Animations (0.56.x: spring key is `dampening`; git main calls it `damping` — check your version's example)
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
-- [noctalia] blur its layer surfaces and let it run its own animations
hl.layer_rule({
	name = "noctalia",
	match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$" },
	no_anim = true,
	ignore_alpha = 0.2,
	blur = true,
	blur_popups = true,
})
-- [noctalia] float its settings window
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
hl.window_rule({ name = "browser-width", match = { class = "^zen.*$" }, scrolling_width = 0.667 })
hl.window_rule({ name = "termiinal-widht", match = { class = "^kitty.*$" }, scrolling_width = 0.333 })

-- Persistent Worskapces per Monitor
hl.workspace_rule({ workspace = "1", monitor = "DP-3", persistent = true, default = true })
hl.workspace_rule({ workspace = "10", monitor = "DP-2", persistent = true, default = true })

------------------------------------------------------------------------------
-- 7. Binds   (wiki: Configuring → Core → Binds, Binds → Flags, Dispatchers)
--    hl.bind("MODS + key", dispatcher_or_function, { flags })
--    Layout-specific actions go through hl.dsp.layout("message") (Scrolling-Layout page).
--    Binds run top-to-bottom; two binds on one key both fire — keep keys unique.
------------------------------------------------------------------------------
-- Apps & session
hl.bind(mainMod .. " + Return", exec(terminal))
hl.bind(mainMod .. " + B", exec(browser))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.kill())
hl.bind(mainMod .. " + SHIFT + slash", exec(terminal .. " --hold hyprctl binds")) -- stand-in for niri's hotkey overlay
hl.bind(mainMod .. " + SHIFT + E", exec(nc .. "panel-toggle session")) -- [noctalia] logout / reboot / shutdown
hl.bind(mainMod .. " + Escape", exec(nc .. "session lock")) -- [noctalia]
hl.bind(mainMod .. " + CTRL + SHIFT + M", hl.dsp.exit())

-- Noctalia surfaces (Noctalia: "IPC Keybinds" + ipc/ pages)
hl.bind(mainMod .. " + Space", exec(nc .. "panel-toggle launcher"))
hl.bind(mainMod .. " + S", exec(nc .. "panel-toggle control-center"))
hl.bind(mainMod .. " + comma", exec(nc .. "settings-toggle"))
hl.bind(mainMod .. " + SHIFT + V", exec(nc .. "panel-toggle clipboard"))
hl.bind("ALT + Tab", exec(nc .. "window-switcher"))
hl.bind("Print", exec(nc .. "screenshot-region"))
hl.bind("SHIFT + Print", exec(nc .. "screenshot-fullscreen"))

-- Navigation. Arrows and vim keys (H J K L) do the same things.
--   Mod        + l/r : focus column, keep it in view
--              + u/d : focus within the column, else the workspace above/below on this monitor
--   Mod+Shift  + l/r : swap column with its neighbour
--              + u/d : move window within the column, else to the workspace above/below (focus follows)
--   Mod+Ctrl   + l/r : scroll the tape one column, focus stays
--   Mod+Alt    + dir : focus monitor        Mod+Alt+Shift + dir : send window to monitor
-- Workspaces are a per-monitor vertical list ordered by id. Going "down" past the last
-- non-empty workspace creates a new one. Requires binds.window_direction_monitor_fallback = false.

-- Ids of the workspaces on a monitor, ascending (specials excluded).
local function monitor_workspaces(mon_name)
	local ids = {}
	for _, ws in ipairs(hl.get_workspaces()) do
		if ws.monitor and ws.monitor.name == mon_name and not ws.special then
			ids[#ids + 1] = ws.id
		end
	end
	table.sort(ids)
	return ids
end

-- One vertical stack across both screens, ids 1–10. Ids ascend top-to-bottom on each
-- monitor (Hyprland picks the slide direction from id order). DP-3 grows downward from
-- workspace 1 (2, 3 … 5); DP-2 grows upward from workspace 10 (9, 8 … 6). Stepping past
-- an anchor crosses to the other screen's anchor. Only the anchors persist.
local stack = {
	["DP-3"] = { anchor = 1, range = { 1, 5 }, grows = "down", beyond = { up = "DP-2" } },
	["DP-2"] = { anchor = 10, range = { 6, 10 }, grows = "up", beyond = { down = "DP-3" } },
}
for name, cfg in pairs(stack) do
	for id = cfg.range[1], cfg.range[2] do
		hl.workspace_rule({
			workspace = tostring(id),
			monitor = name,
			persistent = (id == cfg.anchor),
			default = (id == cfg.anchor),
		})
	end
end

-- An unused id on the growing side of this monitor's stack (nil if none is possible).
local function fresh_workspace_id(mon_name)
	local cfg, used = stack[mon_name], {}
	for _, ws in ipairs(hl.get_workspaces()) do
		if not ws.special then
			used[ws.id] = true
		end
	end
	local ids = monitor_workspaces(mon_name)
	local step = (cfg.grows == "down") and 1 or -1
	local id = (step == 1) and ids[#ids] or ids[1]
	repeat
		id = id + step
	until not used[id] or id < cfg.range[1] or id > cfg.range[2]
	return (id >= cfg.range[1] and id <= cfg.range[2]) and id or nil
end

-- Workspace above/below the active one. "up" = lower id, "down" = higher id on both screens.
-- Past the growing end: a fresh workspace (if the current one isn't empty).
-- Past the anchor: the neighbouring screen's anchor. nil = nothing to do.
local function workspace_in_direction(dir)
	local mon, ws = hl.get_active_monitor(), hl.get_active_workspace()
	if not mon or not ws then
		return nil
	end
	local cfg = stack[mon.name]
	if not cfg then
		return nil
	end
	local best = nil
	for _, id in ipairs(monitor_workspaces(mon.name)) do
		if dir == "up" and id < ws.id and (not best or id > best) then
			best = id
		end
		if dir == "down" and id > ws.id and (not best or id < best) then
			best = id
		end
	end
	if best then
		return best
	end
	if dir == cfg.grows then
		return (ws.windows > 0) and fresh_workspace_id(mon.name) or nil
	end
	local other = cfg.beyond[dir]
	return other and stack[other].anchor or nil
end

-- Is there a tiled window above/below the active one in the same column? (same left edge)
local function window_in_column(w, dir)
	if w.floating or not w.workspace then
		return false
	end
	for _, o in ipairs(hl.get_workspace_windows(w.workspace)) do
		if
			o.address ~= w.address
			and not o.floating
			and o.at.x == w.at.x
			and ((dir == "up" and o.at.y < w.at.y) or (dir == "down" and o.at.y > w.at.y))
		then
			return true
		end
	end
	return false
end

local function focus_workspace(dir)
	return function()
		local ws = workspace_in_direction(dir)
		if ws then
			hl.dispatch(hl.dsp.focus({ workspace = ws }))
		end
	end
end

local function focus_in_column_or_workspace(dir)
	return function()
		local w = hl.get_active_window()
		if w and window_in_column(w, dir) then
			hl.dispatch(hl.dsp.focus({ direction = dir }))
		else
			focus_workspace(dir)()
		end
	end
end

local function move_in_column_or_workspace(dir)
	return function()
		local w = hl.get_active_window()
		if not w then
			return
		end
		if window_in_column(w, dir) then
			hl.dispatch(hl.dsp.window.move({ direction = dir }))
		else
			local ws = workspace_in_direction(dir)
			if ws then
				hl.dispatch(hl.dsp.window.move({ workspace = ws, follow = true }))
			end
		end
	end
end

for _, d in ipairs({
	{ keys = { "left", "H" }, dir = "left", col = "l" },
	{ keys = { "right", "L" }, dir = "right", col = "r" },
	{ keys = { "up", "K" }, dir = "up" },
	{ keys = { "down", "J" }, dir = "down" },
}) do
	for _, k in ipairs(d.keys) do
		if d.col then -- horizontal: layout messages (they know about the tape)
			hl.bind(mainMod .. " + " .. k, hl.dsp.layout("focus " .. d.col))
			hl.bind(mainMod .. " + SHIFT + " .. k, hl.dsp.layout("swapcol " .. d.col))
			hl.bind(mainMod .. " + CTRL + " .. k, hl.dsp.layout("move " .. (d.col == "l" and "-col" or "+col")))
		else -- vertical: column first, then workspace on this monitor
			hl.bind(mainMod .. " + " .. k, focus_in_column_or_workspace(d.dir))
			hl.bind(mainMod .. " + SHIFT + " .. k, move_in_column_or_workspace(d.dir))
		end
		hl.bind(mainMod .. " + ALT + " .. k, hl.dsp.focus({ monitor = d.dir }))
		hl.bind(mainMod .. " + ALT + SHIFT + " .. k, hl.dsp.window.move({ monitor = d.dir, follow = true }))
	end
end

-- Columns (Scrolling-Layout page → Layout messages)
hl.bind(mainMod .. " + bracketleft", hl.dsp.layout("consume_or_expel prev")) -- pull window into / push out of a column
hl.bind(mainMod .. " + bracketright", hl.dsp.layout("consume_or_expel next"))
hl.bind(mainMod .. " + R", hl.dsp.layout("colresize +conf")) -- cycle explicit_column_widths
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.layout("colresize -conf"))
hl.bind(mainMod .. " + minus", hl.dsp.layout("colresize -0.1"))
hl.bind(mainMod .. " + equal", hl.dsp.layout("colresize +0.1"))
hl.bind(mainMod .. " + C", hl.dsp.layout("center"))
hl.bind(mainMod .. " + CTRL + F", hl.dsp.layout("fit expand")) -- take the remaining free width

-- Window state (Dispatchers page → Window)
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" })) -- layout-aware: you can scroll away
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mainMod .. " + V", hl.dsp.window.float()) -- action defaults to toggle
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true }) -- LMB drag
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true }) -- RMB drag

-- Workspaces, niri-style: Mod+N = Nth workspace of the monitor you're on (clamped to the last one);
-- Mod+Shift+N sends the window there and follows it. `m~N` is documented under Naming conventions.
for i = 1, 10 do
	local key = i % 10 -- 10 -> key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = true }))
end
hl.bind(mainMod .. " + Page_Up", focus_workspace("up"))
hl.bind(mainMod .. " + Page_Down", focus_workspace("down"))
hl.bind(mainMod .. " + mouse_up", focus_workspace("up"))
hl.bind(mainMod .. " + mouse_down", focus_workspace("down"))

-- Scratchpad = a named special workspace (Dispatchers page → Special workspaces)
hl.bind(mainMod .. " + grave", hl.dsp.workspace.toggle_special("scratch"))
hl.bind(mainMod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:scratch" }))

-- Media keys through Noctalia so its OSD shows. `locked` = also works on the lock screen.
hl.bind("XF86AudioRaiseVolume", exec(nc .. "volume-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", exec(nc .. "volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", exec(nc .. "volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute", exec(nc .. "mic-mute"), { locked = true })
hl.bind("XF86AudioPlay", exec(nc .. "media toggle"), { locked = true })
hl.bind("XF86AudioPause", exec(nc .. "media toggle"), { locked = true })
hl.bind("XF86AudioNext", exec(nc .. "media next"), { locked = true })
hl.bind("XF86AudioPrev", exec(nc .. "media previous"), { locked = true })

-- For Noctalia Color templates
require("noctalia").apply_theme()
