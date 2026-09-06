-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

-- eDP-2 is not a real display: it is the AMD dGPU's side of the same internal
-- panel connector. `apple_gmux force_igd=y` routes the panel to the Intel iGPU,
-- so the AMD eDP transmitter still asserts HPD but has no EDID and no modes.
-- Hyprland brings it up at 0x0 and numbered workspaces land on it. Must come
-- after the catch-all rule above, which matches every output.
hl.monitor({ output = "eDP-2", disabled = true })
