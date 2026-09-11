-- Keybind cheatsheet (Noctalia plugin kenn/keybind-cheatsheet) reads this file:
--   * a category starts at a comment line of the form  -- <number>. <Name>  (nothing else on it)
--   * each bind's `description` must be a string literal on the same line as `description =`;
--     "Prefix " .. i  works too (the literal part is matched as a prefix)
-- Group order in the panel comes from the category name (Applications, System, Window management,
-- Navigation, Moving windows, Workspace/Monitor, Layout ...), then from bind order.

local terminal = "kitty"
local browser = "zen"
local mainMod = "SUPER"
local nc = "noctalia msg " -- Noctalia v5 IPC prefix
local exec = hl.dsp.exec_cmd -- shorthand: exec("cmd") == hl.dsp.exec_cmd("cmd")

-- 1. Applications
hl.bind(mainMod .. " + Return", exec(terminal), { description = "Open terminal" })
hl.bind(mainMod .. " + B", exec(browser), { description = "Open browser" })
hl.bind(mainMod .. " + Space", exec(nc .. "panel-toggle launcher"), { description = "App launcher" }) -- [noctalia]
hl.bind(mainMod .. " + SHIFT + V", exec(nc .. "panel-toggle clipboard"), { description = "Clipboard history" }) -- [noctalia]
hl.bind("Print", exec(nc .. "screenshot-region"), { description = "Screenshot region" }) -- [noctalia]
hl.bind("SHIFT + Print", exec(nc .. "screenshot-fullscreen"), { description = "Screenshot full screen" }) -- [noctalia]

-- 2. System
-- Noctalia surfaces: see Noctalia's "IPC Keybinds" + ipc/ pages.
hl.bind(mainMod .. " + S", exec(nc .. "panel-toggle control-center"), { description = "Control center" })
hl.bind(mainMod .. " + comma", exec(nc .. "settings-toggle"), { description = "Noctalia settings" })
hl.bind(
	mainMod .. " + SHIFT + slash",
	exec(nc .. "panel-toggle kenn/keybind-cheatsheet:cheatsheet"),
	{ description = "Keybind cheatsheet" }
)
-- hl.bind(mainMod .. " + SHIFT + slash", exec(terminal .. " --hold hyprctl binds")) -- stand-in for niri's hotkey overlay
hl.bind(
	mainMod .. " + SHIFT + E",
	exec(nc .. "panel-toggle session"),
	{ description = "Session menu (logout / reboot / shutdown)" }
) -- [noctalia]
hl.bind(mainMod .. " + Escape", exec(nc .. "session lock"), { description = "Lock screen" }) -- [noctalia]
hl.bind(mainMod .. " + CTRL + SHIFT + M", hl.dsp.exit(), { description = "Exit Hyprland" })

-- 3. Window management
-- Dispatchers page → Window
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close window" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.kill(), { description = "Force-kill window" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Toggle fullscreen" }) -- layout-aware: you can scroll away
hl.bind(
	mainMod .. " + SHIFT + F",
	hl.dsp.window.fullscreen({ mode = "maximized" }),
	{ description = "Toggle maximized" }
)
hl.bind(mainMod .. " + V", hl.dsp.window.float(), { description = "Toggle floating" }) -- action defaults to toggle
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag window" }) -- LMB drag
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" }) -- RMB drag

-- Navigation helpers. Arrows and vim keys (H J K L) do the same things.
--   Mod        + l/r : focus column, keep it in view
--              + u/d : focus within the column, else the workspace above/below on this monitor
--   Mod+Shift  + l/r : swap column with its neighbour
--              + u/d : move window within the column, else to the workspace above/below (focus follows)
--   Mod+Ctrl   + l/r : scroll the tape one column, focus stays
--   Mod+Alt    + dir : focus monitor        Mod+Alt+Shift + dir : send window to monitor
-- Workspaces are a per-monitor vertical list ordered by id. Going "down" past the last
-- non-empty workspace creates a new one. Requires binds.window_direction_monitor_fallback = false.

local dir_keys = {
	left = { "left", "H" },
	right = { "right", "L" },
	up = { "up", "K" },
	down = { "down", "J" },
}

-- Bind `action` to both the arrow key and the vim key of a direction.
-- `mods` goes between mainMod and the key: "" for none, otherwise e.g. "SHIFT" or "ALT + SHIFT".
local function bind_dir(dir, mods, action, opts)
	local combo = (mods == "") and (mainMod .. " + ") or (mainMod .. " + " .. mods .. " + ")
	for _, k in ipairs(dir_keys[dir]) do
		hl.bind(combo .. k, action, opts)
	end
end

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

-- 4. Navigation
-- Horizontal: layout messages (they know about the tape). Vertical: column first, then workspace.
bind_dir("left", "", hl.dsp.layout("focus l"), { description = "Focus column left" })
bind_dir("right", "", hl.dsp.layout("focus r"), { description = "Focus column right" })
bind_dir("up", "", focus_in_column_or_workspace("up"), { description = "Focus up (window, then workspace)" })
bind_dir("down", "", focus_in_column_or_workspace("down"), { description = "Focus down (window, then workspace)" })
bind_dir("left", "CTRL", hl.dsp.layout("move -col"), { description = "Scroll left, keep focus" })
bind_dir("right", "CTRL", hl.dsp.layout("move +col"), { description = "Scroll right, keep focus" })
hl.bind("ALT + Tab", exec(nc .. "window-switcher"), { description = "Window switcher" }) -- [noctalia]

-- 5. Moving windows
bind_dir("left", "SHIFT", hl.dsp.layout("swapcol l"), { description = "Swap column left" })
bind_dir("right", "SHIFT", hl.dsp.layout("swapcol r"), { description = "Swap column right" })
bind_dir("up", "SHIFT", move_in_column_or_workspace("up"), { description = "Move window up (column, then workspace)" })
bind_dir(
	"down",
	"SHIFT",
	move_in_column_or_workspace("down"),
	{ description = "Move window down (column, then workspace)" }
)

-- 6. Workspaces
-- Mod+N focuses workspace id N (key 0 = 10); with the stack above, 1–5 live on DP-3 and 6–10 on DP-2.
-- Mod+Shift+N moves the window there and follows it.
for i = 1, 10 do
	local key = i % 10 -- 10 -> key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Focus workspace " .. i })
	hl.bind(
		mainMod .. " + SHIFT + " .. key,
		hl.dsp.window.move({ workspace = i, follow = true }),
		{ description = "Move window to workspace " .. i }
	)
end
hl.bind(mainMod .. " + Page_Up", focus_workspace("up"), { description = "Focus workspace above" })
hl.bind(mainMod .. " + Page_Down", focus_workspace("down"), { description = "Focus workspace below" })
hl.bind(mainMod .. " + mouse_up", focus_workspace("up"), { description = "Focus workspace above" })
hl.bind(mainMod .. " + mouse_down", focus_workspace("down"), { description = "Focus workspace below" })
-- Scratchpad = a named special workspace (Dispatchers page → Special workspaces)
hl.bind(mainMod .. " + grave", hl.dsp.workspace.toggle_special("scratch"), { description = "Toggle scratchpad" })
hl.bind(
	mainMod .. " + SHIFT + grave",
	hl.dsp.window.move({ workspace = "special:scratch" }),
	{ description = "Send window to scratchpad" }
)

-- 7. Monitors
for _, d in ipairs({ { "left", "left" }, { "right", "right" }, { "up", "above" }, { "down", "below" } }) do
	local dir, where = d[1], d[2]
	bind_dir(dir, "ALT", hl.dsp.focus({ monitor = dir }), { description = "Focus monitor " .. where })
	bind_dir(
		dir,
		"ALT + SHIFT",
		hl.dsp.window.move({ monitor = dir, follow = true }),
		{ description = "Move window to monitor " .. where }
	)
end

-- 8. Scrolling layout
-- Scrolling-Layout page → Layout messages
hl.bind(
	mainMod .. " + bracketleft",
	hl.dsp.layout("consume_or_expel prev"),
	{ description = "Consume into / expel from column (left)" }
)
hl.bind(
	mainMod .. " + bracketright",
	hl.dsp.layout("consume_or_expel next"),
	{ description = "Consume into / expel from column (right)" }
)
hl.bind(mainMod .. " + R", hl.dsp.layout("colresize +conf"), { description = "Next preset column width" }) -- cycles explicit_column_widths
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.layout("colresize -conf"), { description = "Previous preset column width" })
hl.bind(mainMod .. " + minus", hl.dsp.layout("colresize -0.1"), { description = "Narrow column" })
hl.bind(mainMod .. " + equal", hl.dsp.layout("colresize +0.1"), { description = "Widen column" })
hl.bind(mainMod .. " + C", hl.dsp.layout("center"), { description = "Center column" })
hl.bind(mainMod .. " + CTRL + F", hl.dsp.layout("fit expand"), { description = "Expand column into free space" })

-- 9. Audio & playback
-- Media keys go through Noctalia so its OSD shows. `locked` = also works on the lock screen.
hl.bind(
	"XF86AudioRaiseVolume",
	exec(nc .. "volume-up"),
	{ description = "Raise volume", locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	exec(nc .. "volume-down"),
	{ description = "Lower volume", locked = true, repeating = true }
)
hl.bind("XF86AudioMute", exec(nc .. "volume-mute"), { description = "Mute audio", locked = true })
hl.bind("XF86AudioMicMute", exec(nc .. "mic-mute"), { description = "Mute microphone", locked = true })
hl.bind("XF86AudioPlay", exec(nc .. "media toggle"), { description = "Play / pause", locked = true })
hl.bind("XF86AudioPause", exec(nc .. "media toggle"), { description = "Play / pause", locked = true })
hl.bind("XF86AudioNext", exec(nc .. "media next"), { description = "Next track", locked = true })
hl.bind("XF86AudioPrev", exec(nc .. "media previous"), { description = "Previous track", locked = true })
