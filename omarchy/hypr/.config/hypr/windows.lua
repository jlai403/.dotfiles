-- Personal window rules. Cura runs under XWayland (its AppImage forces
-- QT_QPA_PLATFORM=xcb) and Hyprland mis-places its transient dialogs (top-left,
-- tiled) instead of floating them. "Manage Printers" opens the Preferences
-- dialog; float and center it explicitly. See hyprwm/Hyprland#15134.
o.window({ class = "^(UltiMaker-Cura)$", title = "^Preferences$" }, { float = true, center = true })
