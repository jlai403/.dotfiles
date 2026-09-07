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

-- Re-homes.
o.bind("SUPER + SHIFT + CONTROL + ALT + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")
o.bind("SUPER + SHIFT + CONTROL + ALT + F", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + SHIFT + CONTROL + ALT + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("ALT + SLASH", "Toggle split direction", hl.dsp.layout("togglesplit"))

-- macOS Cmd+Q analog: quit the focused app (close all its windows).
o.bind("SUPER + Q", "Quit focused app", "omarchy-hyprland-window-quit-app")

-- App launchers, moved off SUPER+SHIFT to free Cmd+Shift combos.
o.bind("SUPER + CTRL + N", "Editor", { omarchy = "editor" })
o.bind("SUPER + CTRL + W", "Omawrite", { launch = "omawrite" })
o.bind("SUPER + CTRL + P", "Google Photos", { webapp = "https://photos.google.com/", focus = true })
