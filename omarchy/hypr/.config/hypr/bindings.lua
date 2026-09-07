-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Release Omarchy's SUPER+number workspace binds so Cmd+N reaches apps
-- (Zen tab switching, etc.) like macOS. Workspace nav lives on ALT/HYPER.
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  hl.unbind("SUPER + " .. key) -- was: switch to workspace
  hl.unbind("SUPER + SHIFT + " .. key) -- was: move window (follow)
  hl.unbind("SUPER + SHIFT + ALT + " .. key) -- was: move window (silent)
end

-- Shared helpers for the mac shims. send_shortcut_once injects a chord into
-- the focused surface (down + delayed up — Hyprland's send_shortcut can leave
-- synthetic key state stuck). Terminals are detected via the tag Omarchy's
-- defaults apply to terminal windows.
local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

local function active_window_is_terminal()
  local window = hl.get_active_window()
  if not window then
    return false
  end
  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end
  return false
end

-- mac_shortcut: Cmd-style forward (CTRL), silent in terminals — Cmd+key does
-- nothing in Terminal.app either, and forwarding would leak Ctrl chords into
-- the shell (Ctrl+T transposes, etc.).
local function mac_shortcut(mods, key)
  return function()
    if not active_window_is_terminal() then
      send_shortcut_once(mods, key)()
    end
  end
end

-- option_shortcut: forwards CTRL outside terminals; passes the native ALT
-- chord through inside terminals so herdr's alt-driven keymap still receives
-- physical Option presses unchanged.
local function option_shortcut(default_mods, terminal_mods, key)
  return function()
    if active_window_is_terminal() then
      send_shortcut_once(terminal_mods, key)()
    else
      send_shortcut_once(default_mods, key)()
    end
  end
end

-- AeroSpace-style bindings: ALT navigates, HYPER (keyd CapsLock chord) moves.

-- Workspaces 1-5. code:10..14 are the digit keycodes, matching Omarchy's
-- layout-robust convention for number binds.
for workspace = 1, 5 do
  local key = "code:" .. tostring(workspace + 9)
  o.bind("ALT + " .. key, "Switch to workspace " .. workspace,
    hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + CONTROL + ALT + " .. key, "Move window to workspace " .. workspace,
    hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
end

-- Named workspaces.
for _, ws in ipairs({ "a", "e", "w", "c", "n", "d" }) do
  o.bind("ALT + " .. ws:upper(), "Switch to workspace " .. ws,
    hl.dsp.focus({ workspace = "name:" .. ws }))
  o.bind("SUPER + SHIFT + CONTROL + ALT + " .. ws:upper(), "Move window to workspace " .. ws,
    hl.dsp.window.move({ workspace = "name:" .. ws, follow = false }))
end

-- Music: workspace m + cliamp (focus if running, launch otherwise). Shared by
-- the aero ALT+M bind and the Cmd+Ctrl+M launcher re-home below.
local function launch_music()
  hl.dispatch(hl.dsp.focus({ workspace = "name:m" }))
  hl.exec_cmd("omarchy-launch-or-focus-tui cliamp")
end

o.bind("ALT + M", "Music (workspace m + cliamp)", launch_music)

-- Focus with ALT+hjkl, swap window with ALT+SHIFT+hjkl.
o.bind("ALT + H", "Focus left", hl.dsp.focus({ direction = "l" }))
o.bind("ALT + J", "Focus down", hl.dsp.focus({ direction = "d" }))
o.bind("ALT + K", "Focus up", hl.dsp.focus({ direction = "u" }))
o.bind("ALT + L", "Focus right", hl.dsp.focus({ direction = "r" }))
o.bind("ALT + SHIFT + H", "Swap window left", hl.dsp.window.swap({ direction = "l" }))
o.bind("ALT + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("ALT + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("ALT + SHIFT + L", "Swap window right", hl.dsp.window.swap({ direction = "r" }))

-- macOS app-key parity: release SUPER+letters to apps so Zen gets its
-- Cmd-shortcuts (K search, L URL, T tab, W close tab, F find, S save,
-- J downloads, P print, Shift+N/W/P). Displaced window functions are
-- re-homed on the HYPER chord (CapsLock) and ALT below.
for _, key in ipairs({ "K", "L", "T", "W", "F", "S", "J", "P" }) do
  hl.unbind("SUPER + " .. key)
end
hl.unbind("SUPER + SHIFT + N") -- was: Editor
hl.unbind("SUPER + SHIFT + W") -- was: Omawrite
hl.unbind("SUPER + SHIFT + P") -- was: Google Photos
hl.unbind("SUPER + SHIFT + C") -- was: Hey Calendar webapp

-- Re-homes.
o.bind("SUPER + SHIFT + CONTROL + ALT + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")
o.bind("SUPER + SHIFT + CONTROL + ALT + F", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
o.bind("CTRL + ALT + F", "Toggle tiled full screen", "omarchy-hyprland-window-tiled-fullscreen-toggle")
o.bind("SUPER + SHIFT + CONTROL + ALT + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("ALT + SLASH", "Toggle split direction", hl.dsp.layout("togglesplit"))

-- macOS Cmd+Q analog: quit the focused app (close all its windows).
o.bind("SUPER + Q", "Quit focused app", "omarchy-hyprland-window-quit-app")

-- App launchers, moved off SUPER+SHIFT to free Cmd+Shift combos. Omarchy's
-- SUPER+CTRL toggles on F/O/D are released to make room (tiled-fullscreen
-- re-homes to CTRL+ALT+F below; menu/monitor panels live in the omarchy menu).
for _, key in ipairs({ "F", "O", "D" }) do
  hl.unbind("SUPER + CTRL + " .. key)
end
o.bind("SUPER + CTRL + N", "Editor", { omarchy = "editor" })
o.bind("SUPER + CTRL + W", "Omawrite", { launch = "omawrite" })
o.bind("SUPER + CTRL + P", "Google Photos", { webapp = "https://photos.google.com/", focus = true })
o.bind("SUPER + CTRL + F", "Files", { omarchy = "nautilus" })
o.bind("SUPER + CTRL + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })
o.bind("SUPER + CTRL + D", "Docker TUI", { tui = "omarchy-launch-docker-tui" })
o.bind("SUPER + CTRL + M", "Music (workspace m + cliamp)", launch_music)
o.bind("SUPER + CTRL + SHIFT + M", "Spotify", { omarchy = "spotify" })

-- macOS Cmd shim: forward SUPER+key as CTRL+key to the focused app, for
-- apps without a Cmd native mode (Chrome, Electron). Zen gets the full set
-- natively via ui.key.accelKey; this covers everything else.
-- Terminals are skipped (see mac_shortcut above).
o.bind("SUPER + T", "New tab (Cmd shim)", mac_shortcut("CTRL", "T"))
o.bind("SUPER + W", "Close tab (Cmd shim)", mac_shortcut("CTRL", "W"))
o.bind("SUPER + F", "Find (Cmd shim)", mac_shortcut("CTRL", "F"))
o.bind("SUPER + K", "Search (Cmd shim)", mac_shortcut("CTRL", "K"))
o.bind("SUPER + L", "URL bar (Cmd shim)", mac_shortcut("CTRL", "L"))
o.bind("SUPER + J", "Downloads (Cmd shim)", mac_shortcut("CTRL", "J"))
o.bind("SUPER + S", "Save (Cmd shim)", mac_shortcut("CTRL", "S"))
o.bind("SUPER + P", "Print (Cmd shim)", mac_shortcut("CTRL", "P"))
o.bind("SUPER + N", "New window (Cmd shim)", mac_shortcut("CTRL", "N"))
o.bind("SUPER + SHIFT + T", "Reopen tab (Cmd shim)", mac_shortcut("CTRL + SHIFT", "T"))
o.bind("SUPER + SHIFT + N", "Private window (Cmd shim)", mac_shortcut("CTRL + SHIFT", "N"))
o.bind("SUPER + A", "Select all (Cmd shim)", mac_shortcut("CTRL", "A"))
o.bind("SUPER + Z", "Undo (Cmd shim)", mac_shortcut("CTRL", "Z"))
o.bind("SUPER + SHIFT + Z", "Redo (Cmd shim)", mac_shortcut("CTRL + SHIFT", "Z"))
for tab = 1, 9 do
  o.bind("SUPER + code:" .. tostring(tab + 9), "Switch to tab " .. tab .. " (Cmd shim)",
    mac_shortcut("CTRL", tostring(tab)))
end

-- macOS Option text-nav (word move/select/delete via Ctrl equivalents) and
-- Cmd navigation keys. Cmd+arrows = line start/end + doc top/bottom
-- (Super+arrows were Omarchy's window focus — that lives on ALT+hjkl here);
-- Cmd brackets = back/forward in Firefox/Zen.
for _, key in ipairs({ "LEFT", "RIGHT", "UP", "DOWN" }) do
  hl.unbind("SUPER + " .. key) -- was: focus on left/right/above/below window
  hl.unbind("SUPER + SHIFT + " .. key) -- was: swap window (swap lives on ALT+SHIFT+hjkl)
end
hl.unbind("SUPER + TAB") -- was: next workspace
hl.unbind("SUPER + SHIFT + TAB") -- was: previous workspace

o.bind("ALT + LEFT", "Move word left (Option shim)", option_shortcut("CTRL", "ALT", "LEFT"))
o.bind("ALT + RIGHT", "Move word right (Option shim)", option_shortcut("CTRL", "ALT", "RIGHT"))
o.bind("ALT + UP", "Move word up (Option shim)", option_shortcut("CTRL", "ALT", "UP"))
o.bind("ALT + DOWN", "Move word down (Option shim)", option_shortcut("CTRL", "ALT", "DOWN"))
o.bind("ALT + SHIFT + LEFT", "Select word left (Option shim)", option_shortcut("CTRL + SHIFT", "ALT + SHIFT", "LEFT"))
o.bind("ALT + SHIFT + RIGHT", "Select word right (Option shim)", option_shortcut("CTRL + SHIFT", "ALT + SHIFT", "RIGHT"))
o.bind("ALT + SHIFT + UP", "Select word up (Option shim)", option_shortcut("CTRL + SHIFT", "ALT + SHIFT", "UP"))
o.bind("ALT + SHIFT + DOWN", "Select word down (Option shim)", option_shortcut("CTRL + SHIFT", "ALT + SHIFT", "DOWN"))
o.bind("ALT + BACKSPACE", "Delete word (Option shim)", option_shortcut("CTRL", "ALT", "BACKSPACE"))
o.bind("ALT + DELETE", "Delete word forward (Option shim)", option_shortcut("CTRL", "ALT", "DELETE"))

o.bind("SUPER + LEFT", "Line start (Cmd shim)", mac_shortcut("", "HOME"))
o.bind("SUPER + RIGHT", "Line end (Cmd shim)", mac_shortcut("", "END"))
o.bind("SUPER + UP", "Doc top (Cmd shim)", mac_shortcut("", "PAGE_UP"))
o.bind("SUPER + DOWN", "Doc bottom (Cmd shim)", mac_shortcut("", "PAGE_DOWN"))
o.bind("SUPER + BRACKETLEFT", "Back (Cmd shim)", mac_shortcut("CTRL", "BRACKETLEFT"))
o.bind("SUPER + BRACKETRIGHT", "Forward (Cmd shim)", mac_shortcut("CTRL", "BRACKETRIGHT"))

-- Cmd+Shift: select to line/doc boundaries (mirrors the Cmd+arrows shims) and
-- forward the rest of the Cmd+Shift space as Ctrl+Shift so apps keep their
-- shortcuts (bookmarks bar, project search, find previous, go to symbol,
-- save as, search tabs, duplicate line, tab switching). Silent in terminals
-- like all Cmd shims. Launchers displaced by these live on SUPER+CTRL above.
for _, key in ipairs({ "B", "F", "G", "O", "S", "A", "E", "M", "D" }) do
  hl.unbind("SUPER + SHIFT + " .. key) -- was: omarchy launcher (re-homed on SUPER+CTRL)
end
o.bind("SUPER + SHIFT + LEFT", "Select to line start (Cmd shim)", mac_shortcut("SHIFT", "HOME"))
o.bind("SUPER + SHIFT + RIGHT", "Select to line end (Cmd shim)", mac_shortcut("SHIFT", "END"))
o.bind("SUPER + SHIFT + UP", "Select to doc top (Cmd shim)", mac_shortcut("CTRL + SHIFT", "HOME"))
o.bind("SUPER + SHIFT + DOWN", "Select to doc bottom (Cmd shim)", mac_shortcut("CTRL + SHIFT", "END"))
o.bind("SUPER + TAB", "Next tab (Cmd shim)", mac_shortcut("CTRL", "TAB"))
o.bind("SUPER + SHIFT + TAB", "Previous tab (Cmd shim)", mac_shortcut("CTRL + SHIFT", "TAB"))
o.bind("SUPER + SHIFT + B", "Bookmarks bar (Cmd shim)", mac_shortcut("CTRL + SHIFT", "B"))
o.bind("SUPER + SHIFT + F", "Project search (Cmd shim)", mac_shortcut("CTRL + SHIFT", "F"))
o.bind("SUPER + SHIFT + G", "Find previous (Cmd shim)", mac_shortcut("CTRL + SHIFT", "G"))
o.bind("SUPER + SHIFT + O", "Go to symbol (Cmd shim)", mac_shortcut("CTRL + SHIFT", "O"))
o.bind("SUPER + SHIFT + S", "Save As (Cmd shim)", mac_shortcut("CTRL + SHIFT", "S"))
o.bind("SUPER + SHIFT + A", "Search tabs (Cmd shim)", mac_shortcut("CTRL + SHIFT", "A"))
o.bind("SUPER + SHIFT + E", "App chord (Cmd shim)", mac_shortcut("CTRL + SHIFT", "E"))
o.bind("SUPER + SHIFT + M", "App chord (Cmd shim)", mac_shortcut("CTRL + SHIFT", "M"))
o.bind("SUPER + SHIFT + D", "Duplicate line (Cmd shim)", mac_shortcut("CTRL + SHIFT", "D"))
