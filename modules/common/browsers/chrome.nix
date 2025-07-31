{ config, options, pkgs, lib, system, ... }: with lib;
let
  cfg = config.modules.common.browsers.chrome;
  mkModule = lib.my.mkModule system;
in
{
  options.modules.common.browsers.chrome = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    darwin = {
      homebrew.casks = [
        "google-chrome"
      ];
    };

    linux = {
      home.packages = with pkgs; [
        libva-utils
      ];

      home.sessionVariables = {
        LIBVA_DRIVER_NAME = "nvidia";
        LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
      };

      home.programs.chromium = {
        enable = true;
        commandLineArgs = [
          # VAAPI support
          "--enable-features=VaapiVideoDecoder"
          "--disable-features=UseSkiaRenderer"
          "--disable-features=UseChromeOSDirectVideoDecoder"
          "--enable-features=VaapiIgnoreDriverChecks"
          # Force VA-API for specific codecs
          "--enable-features=VaapiVideoDecoderForVP9"
          "--enable-features=VaapiVideoDecoderForVP8"
          "--enable-features=VaapiVideoDecoderForH264"
          "--enable-features=VaapiVideoDecoderForHEVC"
          "--enable-features=VaapiVideoDecoderForAV1"
          # Video acceleration
          "--enable-accelerated-video-decode"
          "--enable-accelerated-vp9-decode"
          "--enable-accelerated-vp8-decode"
          "--enable-accelerated-h264-decode"
          "--enable-accelerated-hevc-decode"
          "--enable-accelerated-av1-decode"
          # Disable software decoders
          "--disable-features=Dav1dVideoDecoder"
          "--disable-features=VpxVideoDecoder"
          "--disable-features=FFmpegVideoDecoder"
          # GPU acceleration
          "--ignore-gpu-blocklist"
          "--enable-gpu-rasterization"
          "--enable-zero-copy"
          # OpenGL implementation
          "--use-gl=angle"
          "--use-angle=gl"
          # Disable problematic features
          "--disable-gpu-driver-bug-workarounds"
        ];
      };
    };
  });
}
