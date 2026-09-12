-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

-- Trackpad: reduce accidental palm input.
hl.config({
  input = {
    -- Don't let a palm-induced pointer move yank window focus (stops the caret
    -- jumping to wherever the cursor lands). Focus changes on click / deliberate
    -- interaction instead.
    follow_mouse = 2,

    -- Compose key on Right Alt. Omarchy's default is CapsLock, which keyd
    -- repurposes as the Hyper key (hold) / Esc (tap).
    kb_options = "compose:ralt",

    touchpad = {
      -- Natural (inverse) scrolling: content follows your fingers.
      natural_scroll = true,

      -- Suppress touchpad while typing (already Hyprland's default, made explicit).
      disable_while_typing = true,

      -- A palm brush must not become a click-drag.
      tap_and_drag = false,

      -- A palm tap must not become a click; require a physical press instead.
      tap_to_click = false,

      -- macOS-style 3-finger drag: rest three fingers and move to drag.
      -- libinput ≥1.28 native (fast flicks still register as swipes).
      drag_3fg = 1,

      -- macOS-like scroll speed (Omarchy's default of 0.4 is sluggish).
      scroll_factor = 1.0,
    },
  },
})

-- 3-finger horizontal swipe switches workspaces (macOS "switch between
-- spaces"); slow 3-finger drags still drag thanks to drag_3fg above.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Per-device cursor snappiness for the built-in trackpad.
hl.device({
  name = "apple-inc.-apple-internal-keyboard-/-trackpad-1",
  sensitivity = 0.15,
})
