{ config, options, pkgs, lib, system, ... }: with lib;
let
  cfg = config.modules.common.browsers.firefox;
  mkModule = lib.my.mkModule system;
in
{
  options.modules.common.browsers.firefox = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    darwin = {
      homebrew.casks = [
        "firefox"
      ];
    };

    linux = {
      home.sessionVariables = {
        # Firefox VA-API environment variables
        MOZ_ENABLE_WAYLAND = "0"; # Use X11 since you're on X11
        MOZ_X11_EGL = "1";
        MOZ_USE_XINPUT2 = "1";
        LIBVA_DRIVER_NAME = "nvidia";
        LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
        # Fix tearing on X11
        MOZ_DISABLE_RDD_SANDBOX = "1";
        __GL_SYNC_TO_VBLANK = "1";
      };

      home.programs = {
        firefox = {
          enable = true;
          profiles.default = {
            settings = {
              # Enable hardware acceleration
              "gfx.webrender.all" = true;
              "gfx.webrender.enabled" = true;
              "layers.acceleration.force-enabled" = true;
              "layers.offmainthreadcomposition.enabled" = true;
              "layers.gpu-process.enabled" = true;

              # Enable VA-API video decoding
              "media.hardware-video-decoding.enabled" = true;
              "media.hardware-video-decoding.force-enabled" = true;
              "media.ffmpeg.vaapi.enabled" = true;
              "media.av1.enabled" = true;
              "media.rdd-vpx.enabled" = false; # Disable software VP8/VP9 in RDD process

              # Fix tearing and vsync issues
              "gfx.webrender.compositor.force-enabled" = true;
              "gfx.webrender.use-optimized-shaders" = true;
              "layers.omtp.enabled" = true;
              "gfx.vsync.hw-vsync.enabled" = true;
              "layout.frame_rate" = 60;
              "gfx.refresh-rate" = 0; # Auto-detect

              # GPU preferences
              "gfx.canvas.azure.backends" = "direct2d1,cairo";
              "gfx.content.azure.backends" = "direct2d1,cairo";
              "image.mem.decode_bytes_at_a_time" = 32768;

              # WebGL
              "webgl.force-enabled" = true;
              "webgl.disabled" = false;

              # Disable software rendering fallbacks
              "gfx.canvas.azure.accelerated" = true;
              "browser.tabs.remote.autostart" = true;

              # Performance tweaks
              "dom.ipc.processCount" = 8;
              "browser.preferences.defaultPerformanceSettings.enabled" = false;
              "dom.ipc.processCount.webIsolated" = 4;

              # Additional anti-tearing settings
              "gfx.x11-egl.force-enabled" = true;
              "widget.dmabuf.force-enabled" = false; # Can cause issues on NVIDIA
            };
          };
        };
      };
    };
  });
}
