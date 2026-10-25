-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 2

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

-- CAUTION: never disable a display by connector *name* unless that name is
-- probe-order-independent. DRM hands out connector names in enumeration order,
-- and the names can swap between boots (see the simpledrm rule below for the
-- name that is safe). Incident precedent: an `eDP-2` disable rule here used to
-- keep the AMD dGPU's phantom transmitter off, until one boot's probe order
-- flipped — the real panel came up as "eDP-2", the rule disabled the only
-- output, and the desktop was black after login. The dGPU is now out of the
-- kernel entirely (blacklist in `omarchy/amdgpu-off`; `task dgpu:on` to bring
-- it back deliberately), and the dGPu rule is deliberately not restored.

-- The firmware boot framebuffer (simpledrm) stays a registered KMS device
-- after i915 takes over graphics, so the catch-all rule above keeps it live as
-- an invisible second screen ("Unknown-1", parked off to the side; numbered
-- workspaces land on it). Disabling by name is safe here: the firmware
-- framebuffer never races the GPU probe order, so its name does not flip
-- between boots the way the GPUs' eDP names do.
hl.monitor({ output = "Unknown-1", disabled = true })
