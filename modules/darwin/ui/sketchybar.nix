{ config, options, lib, pkgs, ... }: with lib;
let
  cfg = config.modules.darwin.ui.sketchybar;
in
{
  options.modules.darwin.ui.sketchybar = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    services.sketchybar.enable = true;
    services.sketchybar.config = ''
          # Icon font: Hack Nerd Font
      # Search for icons here: https://www.nerdfonts.com/cheat-sheet
      #                          ﱦ 齃     ﮂ 爵        ﭵ     ﱦ  ﰊ 異 ﴱ אַ

      ############## BAR ##############
      sketchybar --bar height=40 \
                       y_offset=8 \
                       blur_radius=0 \
                       position=top \
                       padding_left=4 \
                       padding_right=4 \
                       margin=10 \
                       corner_radius=0 \
                       shadow=on \
                       color=0x00000000 \

      ############## GLOBAL DEFAULTS ##############
      sketchybar --default updates=when_shown \
                           icon.font="ZeroCode:Regular:16.0" \
                           icon.color=0xffECEFF4 \
                           icon.highlight_color=0xffE48FA8 \
                           label.font="ZeroCode:Italic:14.0" \
                           label.color=0xffECEFF4 \
                           background.corner_radius=5 \
                           background.height=30

      sketchybar --add item logo left \
                 --set logo icon=  \
                       icon.color=0xff010101 \
                       icon.padding_left=16 \
                       icon.padding_right=16 \
                       icon.font="ZeroCode:Regular:18.0" \
                       background.color=0xff91d7e3 \
                       background.padding_right=8 \
                       background.padding_left=4 \
                       click_script="sketchybar --update"

      SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10")
      SPACES=()

      for i in "$\{!SPACE_ICONS[@]\}"
      do
        sid=$(($i+1))
        SPACES+=(space.$sid)
        sketchybar --add space space.$sid left \
                   --set space.$sid associated_space=$sid \
                                    icon=$\{SPACE_ICONS[i]\} \
                                    icon.padding_left=20 \
                                    icon.padding_right=20 \
                                    icon.highlight_color=0xffE48FA8 \
                                    background.padding_left=-4 \
                                    background.padding_right=-4 \
                                    background.color=0xff3C3E4F \
                                    background.drawing=on \
                                    label.drawing=off \
                                    click_script="yabai -m space --focus $sid"
      done

      sketchybar --add item space_separator left \
                 --set space_separator icon= \
                                       background.padding_left=23 \
                                       background.padding_right=23 \
                                       label.drawing=off \
                                       icon.color=0xff92B3F5

      ############## ITEM DEFAULTS ###############
      sketchybar --default label.padding_left=8 \
                           label.padding_right=8 \
                           icon.padding_left=6 \
                           icon.padding_right=6 \
                           icon.font="Hack Nerd Font:Bold:20.0" \
                           background.height=30 \
                           background.padding_right=4 \
                           background.padding_left=4 \
                           background.corner_radius=5


      ############## RIGHT ITEMS ##############

      sketchybar --add item time_logo right\
                 --set time_logo icon= \
                                 label.drawing=off \
                                 icon.color=0xff121219 \
                                 label.drawing=off \
                                 background.color=0xffF5E3B5

      sketchybar --add item clock_logo right\
                 --set clock_logo icon= \
                                  icon.color=0xff121219\
                                  label.drawing=off \
                                  background.color=0xff92B3F5

      sketchybar --add item power_logo right \
                 --set power_logo icon= \
                       icon.color=0xff121219 \
                       label.drawing=off \
                       background.color=0xffB3E1A7

      sketchybar --add item net_logo right \
                 --set net_logo icon=\
                           icon.color=0xff121219\
                           label.drawing=off \
                           background.color=0xffE0A3AD

      sketchybar --add item pressure_logo right \
                 --set pressure_logo icon=󰈸\
                           icon.color=0xff121219\
                           label.drawing=off \
                           background.color=0xff92B3F5

      sketchybar --subscribe net wifi_change wired_change

      ############## FINALIZING THE SETUP ##############
      sketchybar --update
      sketchybar --hotload on
      echo "sketchybar configuration loaded..."
    '';
  };
}
