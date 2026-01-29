local awful = require("awful")
local filesystem = require("gears.filesystem")
local config_dir = filesystem.get_configuration_dir()
local helpers = require("helpers")

function autorun_apps()
	helpers.run.check_if_running("picom --experimental-backends", nil, function()
		awful.spawn("picom", false)
	end)
end

autorun_apps()
