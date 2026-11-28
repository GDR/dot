-- Hyprland Configuration (Lua)
-- See https://wiki.hypr.land/Configuring/Start/

-- Load Nix-generated theme colors
-- Theme file is written by hyprland.nix as a sibling to hypr/:
--   ~/.config/hypr-theme.lua
local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local theme = dofile(config_home .. "/hypr-theme.lua")

------------------------------------------------------------
-- Monitors
------------------------------------------------------------

-- Top 144 Hz (10-bit)
-- P275MV MAX: 1600 nit peak brightness
local top_monitor = "DP-2"
hl.monitor({
    output = top_monitor,
    mode = "3840x2160@144",
    position = "2160x0",
    scale = 1,
    bitdepth = 10,
})

-- Middle 170 Hz (10-bit)
-- P275MV MAX: 1600 nit peak brightness
local primary_monitor = "DP-3"
hl.monitor({
    output = primary_monitor,
    mode = "3840x2160@170",
    position = "2160x2160",
    scale = 1,
    bitdepth = 10,
})

-- Bottom 60 Hz LG (10-bit, rotated)
local bottom_monitor = "DP-1"
hl.monitor({
    output = bottom_monitor,
    mode = "3840x2160@60",
    position = "0x1320",
    scale = 1,
    bitdepth = 10,
    transform = 1,
})

-- Per-monitor workspace blocks (10 workspaces per screen, keyed by name so DRM order can't shift them)
local monitor_order = { primary_monitor, top_monitor, bottom_monitor }
local monitor_offsets = {
    [primary_monitor] = 0,  -- DP-3: 1..10
    [top_monitor]     = 10, -- DP-2: 11..20
    [bottom_monitor]  = 20, -- DP-1: 21..30
}

for _, mon in ipairs(monitor_order) do
    local offset = monitor_offsets[mon]
    for slot = 1, 10 do
        hl.workspace_rule({
            workspace = tostring(offset + slot),
            monitor = mon,
            default = (slot == 1),
        })
    end
end

hl.workspace_rule({
    workspace = "11", -- slot 9 on DP-2
    monitor = top_monitor,
    gaps_out = { top = 10, right = 1925, bottom = 10, left = 10 }, -- reserves right half of 3840px DP-2 for floating slots
})

------------------------------------------------------------
-- Input
------------------------------------------------------------

hl.config({
    input = {
        kb_layout = "us,ru",
        kb_options = "grp:alt_space_toggle",

        follow_mouse = 0,
        touchpad = {
            natural_scroll = false,
        },

        sensitivity = 0, -- -1.0 to 1.0, 0 means no modification
    },
})

------------------------------------------------------------
-- Cursor
------------------------------------------------------------

hl.config({
    cursor = {
        no_hardware_cursors = true,
        default_monitor = primary_monitor,
    },
})

------------------------------------------------------------
-- Environment variables
------------------------------------------------------------

hl.env("XCURSOR_THEME", "WhiteSur-cursors")
hl.env("XCURSOR_SIZE", "24")
-- NVIDIA env vars — uncomment if re-enabling the NVIDIA GPU
-- hl.env("GBM_BACKEND", "nvidia-drm")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("ENABLE_HDR_WSI", "1")

------------------------------------------------------------
-- General
------------------------------------------------------------

hl.config({
    general = {
        gaps_in = 10,
        gaps_out = 10,
        border_size = 2,
        ["col.active_border"]   = theme.border_active,
        ["col.inactive_border"] = theme.border_inactive,

        layout = "dwindle",

        allow_tearing = false,
    },
})

------------------------------------------------------------
-- Decoration
------------------------------------------------------------

hl.config({
    decoration = {
        rounding = 8,

        blur = {
            enabled = true,
            variant = 0, -- kawase by default; toggled to acrylic (8) while Rofi is open
            size = 10,
            passes = 1,

            vibrancy = 0.1696,

            acrylic = {
                refraction = 22,
                bulb = 48,
                clarity = 0.0, -- 0 = pure creamy blurred backdrop (no sharpTex bleed-through); keeps curved bevel refraction + Fresnel/specular rim
                aberration = 0.03,
                tint = "rgba(cad3f516)",
            },
        },

        shadow = {
            enabled = true,
            range = 25,
            render_power = 3,
            offset = { 0, 8 },
            color = "rgba(000000AA)",
            color_inactive = "rgba(00000077)",
        },
    },
})

------------------------------------------------------------
-- Animations
------------------------------------------------------------

hl.config({
    animations = {
        enabled = true,

        bezier = { "myBezier", 0.05, 0.9, 0.1, 1.05 },

        animation = {
            { "windows", 1, 7, "myBezier" },
            { "windowsOut", 1, 7, "default", "popin 80%" },
            { "border", 1, 10, "default" },
            { "borderangle", 1, 8, "default" },
            { "fade", 1, 7, "default" },
            { "workspaces", 1, 6, "default" },
        },
    },
})

------------------------------------------------------------
-- Layout
------------------------------------------------------------

hl.config({
    dwindle = {
        preserve_split = true,
    },
})

------------------------------------------------------------
-- Misc
------------------------------------------------------------

hl.config({
    misc = {
        force_default_wallpaper = 1,
        disable_hyprland_logo = false,
    },
})

------------------------------------------------------------
-- Window rules
------------------------------------------------------------

-- Float Bitwarden popup from Vivaldi (not all Vivaldi windows)
hl.window_rule({
    match = {
        class = "^(vivaldi-stable)$",
        title = "^(Bitwarden.*)$",
    },
    float = true,
})

-- Right-half floating slots on workspace 9 (DP-2, 3840x2160)
local slots_dp2 = {
    top_right    = { size = "1905 1065", move = "1925 10" },   -- B
    bottom_right = { size = "1905 1065", move = "1925 1085" }, -- D
}

-- Pin Americas to bottom-right slot (D) on slot 9 of DP-2 (workspace 19)
hl.window_rule({
    match = {
        class = "^(steam_proton)$",
        title = "^(Americas.*)$",
    },
    workspace = "11 silent",
    float = true,
    size = slots_dp2.bottom_right.size,
    move = slots_dp2.bottom_right.move,
})

------------------------------------------------------------
-- Layer rules
------------------------------------------------------------

-- Frosted-glass blur behind SwayNC control center and notification popups
hl.layer_rule({
    name = "swaync-control-center-blur",
    match = { namespace = "^swaync-control-center$" },
    blur = true,
    ignore_alpha = 0.2,
})

hl.layer_rule({
    name = "swaync-notification-blur",
    match = { namespace = "^swaync-notification-window$" },
    blur = true,
    ignore_alpha = 0.2,
})

-- Liquid-glass (acrylic) blur behind Rofi launcher
hl.layer_rule({
    name = "rofi-blur",
    match = { namespace = "^rofi$" },
    blur = true,
    ignore_alpha = 0.1,
})

-- Scope native acrylic blur to Rofi's lifetime so other layers/windows keep lightweight kawase
local function set_rofi_acrylic(active)
    if active then
        hl.config({
            decoration = {
                blur = {
                    variant = 0, -- acrylic
                    size = 4,
                    passes = 4,
                    vibrancy = 0.45,
                    vibrancy_darkness = 0.2,
                    contrast = 0.95,
                    brightness = 0.62,
                    noise = 0.018,
                },
            },
        })
    else
        hl.config({
            decoration = {
                blur = {
                    variant = 0, -- kawase
                    size = 4,
                    passes = 4,
                    vibrancy = 0.1696,
                    vibrancy_darkness = 0.0,
                    contrast = 0.8916,
                    brightness = 1.0,
                    noise = 0.0117,
                },
            },
        })
    end
end

hl.on("layer.opened", function(layer)
    if layer and layer.namespace == "rofi" then
        set_rofi_acrylic(true)
    end
end)

hl.on("layer.closed", function(layer)
    if layer and layer.namespace == "rofi" then
        set_rofi_acrylic(false)
    end
end)

------------------------------------------------------------
-- Key bindings
------------------------------------------------------------

local mainMod = "SUPER"

-- Application shortcuts
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- Notifications (SwayNC)
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -d -sw"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }))

-- AwesomeWM-style window navigation & layout manipulation (Super + hjkl / Super + Shift + hjkl)
hl.bind(mainMod .. " + j", hl.dsp.window.cycle_next())
hl.bind(mainMod .. " + k", hl.dsp.window.cycle_next({ prev = true }))
hl.bind(mainMod .. " + l", hl.dsp.layout("splitratio +0.05"), { repeating = true })
hl.bind(mainMod .. " + h", hl.dsp.layout("splitratio -0.05"), { repeating = true })

hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.swap({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.swap({ direction = "r" }))

-- Switch focus between screens:
--   Tap Super+Tab (cycles on release) or hold Super+Tab + 1/2/3 to jump directly
--   (1 = main DP-3, 2 = top DP-2, 3 = side DP-1); Super+Shift+Tab cycles in reverse.
local function cycle_monitor(step)
    local active = hl.get_active_monitor()
    local available = {}
    local idx = 1
    for _, name in ipairs(monitor_order) do
        if hl.get_monitor(name) then
            available[#available + 1] = name
            if active and active.name == name then
                idx = #available
            end
        end
    end
    if #available == 0 then
        return
    end
    local next_idx = ((idx - 1 + step) % #available) + 1
    hl.dispatch(hl.dsp.focus({ monitor = available[next_idx] }))
end

local tab_screen_select = false
local tab_screen_move = false
local tab_picked_screen = false

hl.bind(mainMod .. " + Tab", function()
    tab_screen_select = true
    tab_picked_screen = false
end)
hl.bind(mainMod .. " + Tab", function()
    if tab_screen_select and not tab_picked_screen then
        cycle_monitor(1)
    end
    tab_screen_select = false
    tab_picked_screen = false
end, { release = true })

hl.bind(mainMod .. " + SHIFT + Tab", function()
    tab_screen_move = true
    tab_picked_screen = false
end)
hl.bind(mainMod .. " + SHIFT + Tab", function()
    if tab_screen_move and not tab_picked_screen then
        cycle_monitor(-1)
    end
    tab_screen_move = false
    tab_picked_screen = false
end, { release = true })

-- Per-screen workspaces: 1..9,0 operate on the focused monitor's 10-workspace block
-- (while Super+Tab is held, 1/2/3 jump directly to monitor 1/2/3;
--  while Super+Shift+Tab is held, 1/2/3 move the focused window to that monitor's active workspace)
local function target_ws(slot)
    local mon = hl.get_active_monitor()
    local offset = (mon and monitor_offsets[mon.name]) or 0
    return offset + slot
end

for slot = 1, 10 do
    local key = (slot == 10) and "0" or tostring(slot)
    hl.bind(mainMod .. " + " .. key, function()
        if tab_screen_select and slot <= #monitor_order then
            local target = monitor_order[slot]
            if hl.get_monitor(target) then
                hl.dispatch(hl.dsp.focus({ monitor = target }))
                tab_picked_screen = true
            end
            return
        end
        hl.dispatch(hl.dsp.focus({ workspace = target_ws(slot) }))
    end)
    hl.bind(mainMod .. " + SHIFT + " .. key, function()
        if tab_screen_move and slot <= #monitor_order then
            local ws = hl.get_active_workspace(monitor_order[slot])
            if ws then
                hl.dispatch(hl.dsp.window.move({ workspace = ws.id }))
                tab_picked_screen = true
            end
            return
        end
        hl.dispatch(hl.dsp.window.move({ workspace = target_ws(slot) }))
    end)
end

-- Example special workspace (scratchpad)
-- hl.bind(mainMod .. " + S", hl.dsp.focus({ workspace = "special:magic" }))
-- hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
-- hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
-- hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Screenshot bindings (save to ~/Screenshots + copy to clipboard)
local screenshot = config_home .. "/hypr/hypr-screenshot.sh"
hl.bind("Print", hl.dsp.exec_cmd(screenshot .. " region"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(screenshot .. " full"))

-- Audio controls
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"))

-- Brightness controls
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true })

------------------------------------------------------------
-- Soundpad: play sounds through virtual mic (Super+F1 – Super+F12)
------------------------------------------------------------

for i = 1, 12 do
    hl.bind(mainMod .. " + F" .. i, hl.dsp.exec_cmd("soundpad " .. i))
end

------------------------------------------------------------
-- Autostart
------------------------------------------------------------

local xwayland_primary = config_home .. "/hypr/hypr-xwayland-primary.sh"
local function sync_xwayland_primary()
    if hl.get_monitor(primary_monitor) then
        hl.exec_cmd(xwayland_primary .. " " .. primary_monitor)
    end
end

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")

    -- Set GTK cursor theme for better app compatibility
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")

    -- Set XWayland primary monitor so Wine/Proton/X11 games default to the 170 Hz display
    hl.exec_cmd(xwayland_primary .. " " .. primary_monitor)

    -- Focus the main 170 Hz monitor on startup (DRM enumerates DP-1 as ID 0 first,
    -- and input.follow_mouse = 0 does not transfer focus from cursor placement alone)
    if hl.get_monitor(primary_monitor) then
        hl.dispatch(hl.dsp.focus({ monitor = primary_monitor }))
    end
end)

-- Re-apply XWayland primary monitor after hotplug or layout changes
hl.on("monitor.added", sync_xwayland_primary)
hl.on("monitor.layout_changed", sync_xwayland_primary)

-- Refresh Waybar's focused-monitor top-edge glow indicator
hl.on("monitor.focused", function()
    hl.exec_cmd("pkill -RTMIN+10 waybar")
end)

-- Raise focused floating windows above other floating windows
hl.on("window.active", function(win)
    if win and win.floating then
        hl.dispatch(hl.dsp.window.bring_to_top())
    end
end)
