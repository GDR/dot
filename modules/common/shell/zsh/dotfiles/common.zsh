bindkey '^H' backward-kill-word

# Remap "send-break" (Ctrl+C, SIGINT) from Ctrl+C to Left Meta+C in the Zsh line editor
# This only affects ZLE widgets (line editor), not running programs
# To make Left Meta+C behave like Ctrl+C at the Zsh prompt:
bindkey '^[c' send-break

# Unbind send-break from Ctrl+C at the ZLE level so Ctrl+C does not send SIGINT in the line editor
bindkey -rp '^C'

# Change the interrupt character from Ctrl+C to AltGr+C (¢ - cent symbol)
# This allows Ctrl+C to be used for copy in Mac-like keyboard setup
stty intr 0xA2
