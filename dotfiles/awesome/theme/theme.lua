-- local cjson = require("cjson")
local gears = require("gears")
local gfs = require("gears.filesystem")
local themes_path = gfs.get_themes_dir()
local theme = dofile(themes_path .. "default/theme.lua")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
-- local helpers = require("../helpers/init.lua")

-- Font
theme.font_name = "Hack"
-- theme.font = theme.font_name .. "Medium 10"

-- --- Special
theme.white = "#edeff0"
theme.darker_black = "#060809"
theme.black = "#0c0e0f"
theme.lighter_black = "#121415"
theme.one_bg = "#161819"
theme.one_bg2 = "#1f2122"
theme.one_bg3 = "#27292a"
theme.grey = "#343637"
theme.grey_fg = "#3e4041"
theme.grey_fg2 = "#484a4b"
theme.light_grey = "#505253"

theme.transparent = "#00000000"

--- Black
theme.color0 = "#232526"
theme.color8 = "#2c2e2f"

--- Red
theme.color1 = "#df5b61"
theme.color9 = "#e8646a"

--- Green
theme.color2 = "#78b892"
theme.color10 = "#81c19b"

--- Yellow
theme.color3 = "#de8f78"
theme.color11 = "#e79881"

--- Blue
theme.color4 = "#6791c9"
theme.color12 = "#709ad2"

--- Magenta
theme.color5 = "#bc83e3"
theme.color13 = "#c58cec"

--- Cyan
theme.color6 = "#67afc1"
theme.color14 = "#70b8ca"

--- White
theme.color7 = "#e4e6e7"
theme.color15 = "#f2f4f5"

-- --- Background Colors
theme.bg_normal = theme.black
theme.bg_focus = theme.grey
theme.bg_urgent = theme.black
theme.bg_minimize = theme.black

--- Gaps
theme.useless_gap = dpi(4)

--- Borders
theme.border_width = 0
theme.oof_border_width = 0
theme.border_color_marked = theme.titlebar_bg
theme.border_color_active = theme.titlebar_bg
theme.border_color_normal = theme.titlebar_bg
theme.border_color_new = theme.titlebar_bg
theme.border_color_urgent = theme.titlebar_bg
theme.border_color_floating = theme.titlebar_bg
theme.border_color_maximized = theme.titlebar_bg
theme.border_color_fullscreen = theme.titlebar_bg

--- Wibar
theme.wibar_bg = "#101213"

--- Corner Radius
theme.border_radius = 12

--- Edge snap
theme.snap_bg = theme.color8
-- theme.snap_shape = helpers.ui.rrect(0)

theme.wallpaper = gears.surface.load_uncached(gfs.get_configuration_dir() .. "theme/assets/wave.png")

return theme