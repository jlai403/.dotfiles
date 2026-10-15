-- Personal window rules.

-- Cura runs under XWayland (its AppImage forces QT_QPA_PLATFORM=xcb) and
-- Hyprland mis-places X11 transient dialogs (top-left, tiled) instead of
-- floating them relative to the parent. Every Cura dialog is an
-- ApplicationModal Qt Quick Window (UM/Qt/qml/UM/Dialog.qml), so `modal`
-- catches all of them, not just Preferences. See hyprwm/Hyprland#15134.
o.window({ class = "^(UltiMaker-Cura)$", modal = true }, { float = true, center = true })

-- Hovering the main window hands it focus (input:follow_mouse=2); Qt answers by
-- re-activating the modal dialog it is blocked by
-- (QXcbWindow::relayFocusToModalWindow) and Hyprland warps the cursor to the
-- middle of that dialog (CWindow::activate -> warpCursor), so the pointer snaps
-- back every time it leaves the dialog. Keep hover-focus off the main window.
o.window({ class = "^(UltiMaker-Cura)$", modal = false }, { no_follow_mouse = true })
