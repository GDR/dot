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
hl.monitor({
    output = "DP-1",
    mode = "3840x2160@60",
    position = "0x1320",
    scale = 1,
    bitdepth = 10,
    transform = 1,
})

-- Make workspace 1 the default workspace on the main 170 Hz monitor
-- (otherwise DRM enumerates DP-1 as ID 0 and assigns workspace 1 to it)
hl.workspace_rule({
    workspace = "1",
    monitor = primary_monitor,
    default = true,
})

hl.workspace_rule({
    workspace = "9",
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
        gaps_in = 5,
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
            color = "rgba(000000BB)",
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

-- Pin Americas to bottom-right slot (D) on workspace 9 (DP-2)
hl.window_rule({
    match = {
        class = "^(steam_proton)$",
        title = "^(Americas.*)$",
    },
    workspace = "9 silent",
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
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle
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

-- Move focus with mainMod + vim keys
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "d" }))

-- Switch workspaces / Move windows to workspaces (loop)
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

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
