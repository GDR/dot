# Catppuccin Macchiato — https://catppuccin.com
# A dark theme with cool blue-purple tones and warm accents
{
  name = "catppuccin-macchiato";
  displayName = "Catppuccin Macchiato";
  variant = "dark";

  # ── Core palette ──────────────────────────────────────────────────────────
  # Full Catppuccin Macchiato palette (darkest → lightest)
  colors = {
    # Backgrounds (dark → light)
    crust = "#181926";
    mantle = "#1e2030";
    base = "#24273a";
    surface0 = "#363a4f";
    surface1 = "#494d64";
    surface2 = "#5b6078";

    # Text / overlays (dark → light)
    overlay0 = "#6e738d";
    overlay1 = "#8087a2";
    overlay2 = "#939ab7";
    subtext0 = "#a5adcb";
    subtext1 = "#b8c0e0";
    text = "#cad3f5";

    # Accent colors
    lavender = "#b7bdf8";
    blue = "#8aadf4";
    sapphire = "#7dc4e4";
    sky = "#91d7e3";
    teal = "#8bd5ca";
    green = "#a6da95";
    yellow = "#eed49f";
    peach = "#f5a97f";
    maroon = "#ee99a0";
    red = "#ed8796";
    pink = "#f5bde6";
    mauve = "#c6a0f6";
    flamingo = "#f0c6c6";
    rosewater = "#f4dbd6";
  };

  # ── Semantic role aliases ─────────────────────────────────────────────────
  roles = {
    background = "#24273a"; # base
    backgroundAlt = "#1e2030"; # mantle
    backgroundFloat = "#363a4f"; # surface0

    foreground = "#cad3f5"; # text
    foregroundMuted = "#b8c0e0"; # subtext1
    foregroundDim = "#939ab7"; # overlay2

    accent = "#c6a0f6"; # mauve (Catppuccin signature purple)
    accentAlt = "#8aadf4"; # blue

    error = "#ed8796"; # red
    warning = "#f5a97f"; # peach
    success = "#a6da95"; # green
    info = "#7dc4e4"; # sapphire

    border = "#494d64"; # surface1
    borderFocused = "#c6a0f6"; # mauve
    borderInactive = "#363a4f"; # surface0

    selection = "#494d64"; # surface1
  };

  # ── Terminal 16-color palette ─────────────────────────────────────────────
  # Uses Catppuccin's rich palette to avoid repeats.
  # Bright row uses distinct accents: maroon, peach, sapphire, mauve, sky
  # (instead of repeating the normal row colors).
  #
  #  0  black         surface1   → dark panel surface
  #  1  red           red        → natural
  #  2  green         green      → natural
  #  3  yellow        yellow     → natural
  #  4  blue          blue       → natural
  #  5  magenta       pink       → warm pink fills magenta slot
  #  6  cyan          teal       → natural
  #  7  white         subtext1   → muted foreground
  #  8  bright black  overlay0   → lighter than surface1 → two distinct grays
  #  9  bright red    maroon     → warm variant of red, distinct
  # 10  bright green  green      → no bright variant available, repeats
  # 11  bright yellow peach      → orange-yellow, distinct from yellow
  # 12  bright blue   sapphire   → icy blue, distinct from blue
  # 13  bright mag    mauve      → rich purple, distinct from pink
  # 14  bright cyan   sky        → lighter teal, distinct from teal
  # 15  bright white  text       → full foreground
  terminal = {
    black = "#494d64"; # surface1  (ansi 0)
    red = "#ed8796"; # red       (ansi 1)
    green = "#a6da95"; # green     (ansi 2)
    yellow = "#eed49f"; # yellow    (ansi 3)
    blue = "#8aadf4"; # blue      (ansi 4)
    magenta = "#f5bde6"; # pink      (ansi 5)
    cyan = "#8bd5ca"; # teal      (ansi 6)
    white = "#b8c0e0"; # subtext1  (ansi 7)

    brightBlack = "#6e738d"; # overlay0  (ansi 8)  — lighter than surface1
    brightRed = "#ee99a0"; # maroon    (ansi 9)  — warm red variant
    brightGreen = "#a6da95"; # green     (ansi 10) — no bright variant
    brightYellow = "#f5a97f"; # peach     (ansi 11) — orange-yellow accent
    brightBlue = "#7dc4e4"; # sapphire  (ansi 12) — icy blue variant
    brightMagenta = "#c6a0f6"; # mauve     (ansi 13) — rich purple
    brightCyan = "#91d7e3"; # sky       (ansi 14) — lighter teal
    brightWhite = "#cad3f5"; # text      (ansi 15)

    background = "#24273a"; # base
    foreground = "#cad3f5"; # text
    cursor = "#c6a0f6"; # mauve
    cursorText = "#24273a"; # base
    selection = "#494d64"; # surface1
    selectionText = "#cad3f5"; # text
  };

  # ── Font recommendations ───────────────────────────────────────────────────
  fonts = {
    mono = "JetBrainsMono Nerd Font";
    monoSize = 13;
    sans = "Inter";
    sansSize = 11;
  };
}
