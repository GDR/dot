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
hl.monitor({
    output = "DP-2",
    mode = "3840x2160@144",
    position = "2160x0",
    scale = 1,
    bitdepth = 10,
})

-- Middle 170 Hz (10-bit)
-- P275MV MAX: 1600 nit peak brightness
hl.monitor({
    output = "DP-3",
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
            size = 3,
            passes = 1,

            vibrancy = 0.1696,
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

------------------------------------------------------------
-- Key bindings
------------------------------------------------------------

local mainMod = "SUPER"

-- Application shortcuts
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

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

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("dunst")
    hl.exec_cmd("swww-daemon")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")

    -- Set GTK cursor theme for better app compatibility
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")
end)
