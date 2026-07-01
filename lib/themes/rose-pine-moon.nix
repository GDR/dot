# Rosé Pine Moon — https://rosepinetheme.com
# A dark, muted theme with dreamy purple highlights
{
  name = "rose-pine-moon";
  displayName = "Rosé Pine Moon";
  variant = "dark";

  # ── Core palette ──────────────────────────────────────────────────────────
  # Named semantically following the official Rosé Pine naming convention
  colors = {
    base = "#232136"; # Background
    surface = "#2a273f"; # Raised surface (panels, popups)
    overlay = "#393552"; # Overlays (dialogs, menus)
    muted = "#6e6a86"; # Muted text (disabled, placeholders)
    subtle = "#908caa"; # Subtle text (comments, secondary info)
    text = "#e0def4"; # Main foreground text

    love = "#eb6f92"; # Red/error/git-deleted
    gold = "#f6c177"; # Yellow/warning/git-modified
    rose = "#ea9a97"; # Salmon/orange accent
    pine = "#3e8fb0"; # Blue/info/git-added
    foam = "#9ccfd8"; # Teal/cyan
    iris = "#c4a7e7"; # Purple/keywords

    # Highlight states
    highlightLow = "#2a283e"; # Subtle selection / hover
    highlightMed = "#44415a"; # Medium selection / active line
    highlightHigh = "#56526e"; # Strong highlight / focused element
  };

  # ── Semantic role aliases ─────────────────────────────────────────────────
  # Convenience mappings for use in module configs
  roles = {
    background = "#232136"; # base
    backgroundAlt = "#2a273f"; # surface
    backgroundFloat = "#393552"; # overlay

    foreground = "#e0def4"; # text
    foregroundMuted = "#908caa"; # subtle
    foregroundDim = "#6e6a86"; # muted

    accent = "#c4a7e7"; # iris  (primary accent — borders, highlights)
    accentAlt = "#9ccfd8"; # foam  (secondary accent)

    error = "#eb6f92"; # love
    warning = "#f6c177"; # gold
    success = "#9ccfd8"; # foam
    info = "#3e8fb0"; # pine

    border = "#44415a"; # highlightMed
    borderFocused = "#c4a7e7"; # iris
    borderInactive = "#2a283e"; # highlightLow

    selection = "#44415a"; # highlightMed
  };

  # ── Terminal 16-color palette ─────────────────────────────────────────────
  # ANSI colors mapped to the theme palette for terminal emulators.
  #
  # Strategy: all 6 accent colors get unique slots in 0–7 by re-assigning
  # roles (pine→green, foam→blue, rose→cyan). Bright row mirrors by convention.
  # Slots 0 and 8 use different background shades for two distinct grays.
  #
  #  0  black         overlay  → darkest surface, "off" black
  #  1  red           love     → natural
  #  2  green         pine     → cool teal-blue reads as green in context
  #  3  yellow        gold     → natural
  #  4  blue          foam     → airy teal fills the blue role
  #  5  magenta       iris     → purple ≈ magenta, natural
  #  6  cyan          rose     → warm pink fills the leftover slot
  #  7  white         text     → natural foreground
  #  8  bright black  muted    → lighter than overlay → two distinct grays
  # 9–14              repeats  → conventional for 6-accent palettes
  # 15 bright white   text     → same as 7 (terminal convention)
  terminal = {
    black = "#232136"; # overlay  (ansi 0)
    red = "#eb6f92"; # love     (ansi 1)
    green = "#3e8fb0"; # pine     (ansi 2) — re-mapped: pine fills green slot
    yellow = "#f6c177"; # gold     (ansi 3)
    blue = "#9ccfd8"; # foam     (ansi 4) — re-mapped: foam fills blue slot
    magenta = "#c4a7e7"; # iris     (ansi 5)
    cyan = "#ea9a97"; # rose     (ansi 6) — re-mapped: rose fills cyan slot
    white = "#e0def4"; # text     (ansi 7)

    brightBlack = "#6e6a86"; # muted    (ansi 8)  — different shade from overlay
    brightRed = "#eb6f92"; # love     (ansi 9)
    brightGreen = "#3e8fb0"; # pine     (ansi 10)
    brightYellow = "#f6c177"; # gold     (ansi 11)
    brightBlue = "#9ccfd8"; # foam     (ansi 12)
    brightMagenta = "#c4a7e7"; # iris     (ansi 13)
    brightCyan = "#ea9a97"; # rose     (ansi 14)
    brightWhite = "#e0def4"; # text     (ansi 15)

    background = "#232136"; # base
    foreground = "#e0def4"; # text
    cursor = "#c4a7e7"; # iris
    cursorText = "#232136"; # base
    selection = "#44415a"; # highlightMed
    selectionText = "#e0def4"; # text
  };

  # ── Font recommendations ───────────────────────────────────────────────────
  fonts = {
    mono = "JetBrainsMono Nerd Font";
    monoSize = 13;
    sans = "Inter";
    sansSize = 11;
  };
}
