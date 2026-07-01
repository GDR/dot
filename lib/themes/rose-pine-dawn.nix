# Rosé Pine Moon — https://rosepinetheme.com
# A light, muted theme with warm highlights
{
  name = "rose-pine-moon";
  displayName = "Rosé Pine Moon";
  variant = "light";

  # ── Core palette ──────────────────────────────────────────────────────────
  # Named semantically following the official Rosé Pine naming convention
  colors = {
    base = "#faf4ed"; # Background
    surface = "#fffaf3"; # Raised surface (panels, popups)
    overlay = "#f2e9e1"; # Overlays (dialogs, menus)
    muted = "#9893a5"; # Muted text (disabled, placeholders)
    subtle = "#797593"; # Subtle text (comments, secondary info)
    text = "#464261"; # Main foreground text

    love = "#b4637a"; # Red/error/git-deleted
    gold = "#ea9d34"; # Yellow/warning/git-modified
    rose = "#d7827e"; # Salmon/orange accent
    pine = "#286983"; # Blue/info/git-added
    foam = "#56949f"; # Teal/cyan
    iris = "#907aa9"; # Purple/keywords

    # Highlight states
    highlightLow = "#f4ede8"; # Subtle selection / hover
    highlightMed = "#dfdad9"; # Medium selection / active line
    highlightHigh = "#cecacd"; # Strong highlight / focused element
  };

  # ── Semantic role aliases ─────────────────────────────────────────────────
  # Convenience mappings for use in module configs
  roles = {
    background = "#faf4ed"; # base
    backgroundAlt = "#fffaf3"; # surface
    backgroundFloat = "#f2e9e1"; # overlay

    foreground = "#464261"; # text
    foregroundMuted = "#797593"; # subtle
    foregroundDim = "#9893a5"; # muted

    accent = "#907aa9"; # iris  (primary accent — borders, highlights)
    accentAlt = "#56949f"; # foam  (secondary accent)

    error = "#b4637a"; # love
    warning = "#ea9d34"; # gold
    success = "#56949f"; # foam
    info = "#286983"; # pine

    border = "#dfdad9"; # highlightMed
    borderFocused = "#907aa9"; # iris
    borderInactive = "#f4ede8"; # highlightLow

    selection = "#dfdad9"; # highlightMed
  };

  # ── Terminal 16-color palette ─────────────────────────────────────────────
  # ANSI colors mapped to the theme palette for terminal emulators
  terminal = {
    black = "#f2e9e1"; # overlay  (ansi 0)
    red = "#b4637a"; # love     (ansi 1)
    green = "#56949f"; # foam     (ansi 2)
    yellow = "#ea9d34"; # gold     (ansi 3)
    blue = "#286983"; # pine     (ansi 4)
    magenta = "#907aa9"; # iris     (ansi 5)
    cyan = "#56949f"; # foam     (ansi 6)
    white = "#464261"; # text     (ansi 7)

    brightBlack = "#9893a5"; # muted    (ansi 8)
    brightRed = "#b4637a"; # love     (ansi 9)
    brightGreen = "#56949f"; # foam     (ansi 10)
    brightYellow = "#ea9d34"; # gold     (ansi 11)
    brightBlue = "#286983"; # pine     (ansi 12)
    brightMagenta = "#907aa9"; # iris     (ansi 13)
    brightCyan = "#56949f"; # foam     (ansi 14)
    brightWhite = "#faf4ed"; # base     (ansi 15)

    background = "#faf4ed"; # base
    foreground = "#464261"; # text
    cursor = "#907aa9"; # iris
    cursorText = "#faf4ed"; # base
    selection = "#dfdad9"; # highlightMed
    selectionText = "#464261"; # text
  };

  # ── Font recommendations ───────────────────────────────────────────────────
  fonts = {
    mono = "JetBrainsMono Nerd Font";
    monoSize = 13;
    sans = "Inter";
    sansSize = 11;
  };
}
