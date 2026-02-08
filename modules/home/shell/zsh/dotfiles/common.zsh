# Common zsh configuration
# This file is live-editable - changes take effect on new shell sessions

# Fix colors in SSH sessions — remote may lack terminfo for the client terminal
# (e.g. xterm-ghostty). Fall back to xterm-256color which is universally available.
[[ -n "$SSH_TTY" && ! -e "/usr/share/terminfo/${TERM[1]}/$TERM" && ! -e "$HOME/.terminfo/${TERM[1]}/$TERM" ]] && export TERM=xterm-256color
