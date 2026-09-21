local terminal = "kitty"
local browser = "zen"
local mainMod = "SUPER"
local nc = "noctalia msg "
local exec = hl.dsp.exec_cmd

-- Bind `action` to both the arrow and vim key of a direction.
-- mods: "" or e.g. "SHIFT", "CTRL + SHIFT"
local keys = { left = { "left", "H" }, right = { "right", "L" }, up = { "up", "K" }, down = { "down", "J" } }
local function bind_dir(dir, mods, action, opts)
	local prefix = mainMod .. " + " .. (mods == "" and "" or mods .. " + ")
	for _, k in ipairs(keys[dir]) do
		hl.bind(prefix .. k, action, opts)
	end
end

-- Is there a tiled window above/below `w` in its column (same left edge)?
local function in_column(w, dir)
	if w.floating then
		return false
	end
	for _, o in ipairs(hl.get_workspace_windows(w.workspace)) do
		if not o.floating and o.at.x == w.at.x and ((dir == "up" and o.at.y < w.at.y) or (dir == "down" and o.at.y > w.at.y)) then
			return true
		end
	end
	return false
end

-- Focus (or move the window) within the column; at the end of the column, go to workspace `ws` instead.
local WS_ABOVE, WS_BELOW = "m-1", "r+1" -- r+1 also creates a fresh workspace past the last one
local function column_then_workspace(dir, ws, move)
	return function()
		local w = hl.get_active_window()
		if w and in_column(w, dir) then
			hl.dispatch(move and hl.dsp.window.move({ direction = dir }) or hl.dsp.focus({ direction = dir }))
		else
			hl.dispatch(move and hl.dsp.window.move({ workspace = ws, follow = true }) or hl.dsp.focus({ workspace = ws }))
		end
	end
end

-- One persistent workspace per monitor (DP-2 above DP-3); the rest are created on demand.
hl.workspace_rule({ workspace = "1", monitor = "DP-3", persistent = true, default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-2", persistent = true, default = true })

-- 1. Applications
hl.bind(mainMod .. " + Return", exec(terminal), { description = "Open terminal" })
hl.bind(mainMod .. " + B", exec(browser), { description = "Open browser" })
hl.bind(mainMod .. " + Space", exec(nc .. "panel-toggle launcher"), { description = "App launcher" })
hl.bind(mainMod .. " + SHIFT + V", exec(nc .. "panel-toggle clipboard"), { description = "Clipboard history" })
hl.bind("Print", exec(nc .. "screenshot-region"), { description = "Screenshot region" })
hl.bind("SHIFT + Print", exec(nc .. "screenshot-fullscreen"), { description = "Screenshot full screen" })

-- 2. System
hl.bind(mainMod .. " + S", exec(nc .. "panel-toggle control-center"), { description = "Control center" })
hl.bind(mainMod .. " + comma", exec(nc .. "settings-toggle"), { description = "Noctalia settings" })
hl.bind(
	mainMod .. " + SHIFT + slash",
	exec(nc .. "panel-toggle kenn/keybind-cheatsheet:cheatsheet"),
	{ description = "Keybind cheatsheet" }
)
hl.bind(mainMod .. " + SHIFT + E", exec(nc .. "panel-toggle session"), { description = "Session menu" })
hl.bind(mainMod .. " + Escape", exec(nc .. "session lock"), { description = "Lock screen" })
hl.bind(mainMod .. " + CTRL + SHIFT + M", hl.dsp.exit(), { description = "Exit Hyprland" })
hl.bind(mainMod .. " + O", hl.plugin.scrolloverview.overview("toggle"), { description = "Workspace overview" })

-- 3. Window management
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close window" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.kill(), { description = "Force-kill window" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Toggle fullscreen" })
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "Toggle maximized" })
hl.bind(mainMod .. " + V", hl.dsp.window.float(), { description = "Toggle floating" })
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

-- 4. Navigation
-- Left/right walk the columns. Up/down walk the column, then the workspaces on this monitor.
bind_dir("left", "", hl.dsp.layout("focus l"), { description = "Focus column left" })
bind_dir("right", "", hl.dsp.layout("focus r"), { description = "Focus column right" })
bind_dir("up", "", column_then_workspace("up", WS_ABOVE), { description = "Focus up (window, then workspace)" })
bind_dir("down", "", column_then_workspace("down", WS_BELOW), { description = "Focus down (window, then workspace)" })
hl.bind("ALT + Tab", exec(nc .. "window-switcher"), { description = "Window switcher" })

-- 5. Moving windows
bind_dir("left", "SHIFT", hl.dsp.layout("swapcol l"), { description = "Swap column left" })
bind_dir("right", "SHIFT", hl.dsp.layout("swapcol r"), { description = "Swap column right" })
bind_dir("up", "SHIFT", column_then_workspace("up", WS_ABOVE, true),
	{ description = "Move window up (column, then workspace)" })
bind_dir("down", "SHIFT", column_then_workspace("down", WS_BELOW, true),
	{ description = "Move window down (column, then workspace)" })

-- 6. Workspaces
for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Focus workspace " .. i })
	hl.bind(
		mainMod .. " + SHIFT + " .. key,
		hl.dsp.window.move({ workspace = i, follow = true }),
		{ description = "Move window to workspace " .. i }
	)
end
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = WS_ABOVE }), { description = "Focus workspace above" })
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = WS_BELOW }), { description = "Focus workspace below" })
hl.bind(mainMod .. " + grave", hl.dsp.workspace.toggle_special("scratch"), { description = "Toggle scratchpad" })
hl.bind(
	mainMod .. " + SHIFT + grave",
	hl.dsp.window.move({ workspace = "special:scratch" }),
	{ description = "Send window to scratchpad" }
)

-- 7. Monitors
bind_dir("up", "CTRL", hl.dsp.focus({ monitor = "up" }), { description = "Focus monitor above" })
bind_dir("down", "CTRL", hl.dsp.focus({ monitor = "down" }), { description = "Focus monitor below" })
bind_dir(
	"up",
	"CTRL + SHIFT",
	hl.dsp.window.move({ monitor = "up", follow = true }),
	{ description = "Move window to monitor above" }
)
bind_dir(
	"down",
	"CTRL + SHIFT",
	hl.dsp.window.move({ monitor = "down", follow = true }),
	{ description = "Move window to monitor below" }
)

-- 8. Scrolling layout
hl.bind(mainMod .. " + bracketleft", hl.dsp.layout("consume_or_expel prev"),
	{ description = "Consume / expel column (left)" })
hl.bind(mainMod .. " + bracketright", hl.dsp.layout("consume_or_expel next"),
	{ description = "Consume / expel column (right)" })
hl.bind(mainMod .. " + R", hl.dsp.layout("colresize +conf"), { description = "Next preset column width" })
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.layout("colresize -conf"), { description = "Previous preset column width" })
hl.bind(mainMod .. " + minus", hl.dsp.layout("colresize -0.1"), { description = "Narrow column" })
hl.bind(mainMod .. " + equal", hl.dsp.layout("colresize +0.1"), { description = "Widen column" })
hl.bind(mainMod .. " + C", hl.dsp.layout("center"), { description = "Center column" })
hl.bind(mainMod .. " + CTRL + F", hl.dsp.layout("fit expand"), { description = "Expand column into free space" })

-- 9. Audio & playback
-- Routed through Noctalia so its OSD shows; `locked` = works on the lock screen.
hl.bind("XF86AudioRaiseVolume", exec(nc .. "volume-up"),
	{ description = "Raise volume", locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", exec(nc .. "volume-down"),
	{ description = "Lower volume", locked = true, repeating = true })
hl.bind("XF86AudioMute", exec(nc .. "volume-mute"), { description = "Mute audio", locked = true })
hl.bind("XF86AudioMicMute", exec(nc .. "mic-mute"), { description = "Mute microphone", locked = true })
hl.bind("XF86AudioPlay", exec(nc .. "media toggle"), { description = "Play / pause", locked = true })
hl.bind("XF86AudioPause", exec(nc .. "media toggle"), { description = "Play / pause", locked = true })
hl.bind("XF86AudioNext", exec(nc .. "media next"), { description = "Next track", locked = true })
hl.bind("XF86AudioPrev", exec(nc .. "media previous"), { description = "Previous track", locked = true })
