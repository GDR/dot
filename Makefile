# ──────────────────────────────────────────────────────────────────────────────
# dot — host management
#
#   make update          Update all flake inputs (lock file)
#   make fmt             Format all Nix files
#   make check           nix flake check
#
#   make all             Switch all reachable hosts
#   make mac-brightstar  Switch the local Mac (darwin-rebuild)
#   make nix-oldstar     Rebuild nix-oldstar via SSH + nixos-rebuild
#   make nix-goldstar    Rebuild nix-goldstar via SSH + nixos-rebuild
#   make nixos           Rebuild all NixOS hosts
#   make darwin          Switch all Darwin hosts
# ──────────────────────────────────────────────────────────────────────────────

.DEFAULT_GOAL := help
.PHONY: help all update fmt check \
        mac-brightstar \
        nix-oldstar nix-goldstar \
        nixos darwin

# ── Help ──────────────────────────────────────────────────────────────────────
help:
	@printf "\n  \033[1mdot — host management\033[0m\n\n"
	@printf "  \033[36mmake all\033[0m            Switch / deploy every host\n"
	@printf "  \033[36mmake darwin\033[0m         Switch all Darwin (macOS) hosts\n"
	@printf "  \033[36mmake nixos\033[0m          Rebuild all NixOS hosts via SSH\n"
	@printf "\n"
	@printf "  \033[36mmake mac-brightstar\033[0m darwin-rebuild switch for mac-brightstar (this machine)\n"
	@printf "  \033[36mmake nix-oldstar\033[0m    nixos-rebuild switch for nix-oldstar (remote)\n"
	@printf "  \033[36mmake nix-goldstar\033[0m   nixos-rebuild switch for nix-goldstar (remote)\n"
	@printf "\n"
	@printf "  \033[36mmake update\033[0m         nix flake update (refresh lock file)\n"
	@printf "  \033[36mmake fmt\033[0m            nixpkgs-fmt on all *.nix files\n"
	@printf "  \033[36mmake check\033[0m          nix flake check\n"
	@printf "\n"

# ── Top-level targets ─────────────────────────────────────────────────────────
all: darwin nixos

darwin: mac-brightstar

nixos: nix-oldstar nix-goldstar

# ── Darwin hosts ──────────────────────────────────────────────────────────────
# mac-brightstar is the machine you're usually sitting at, so we run
# darwin-rebuild directly (no SSH needed).
mac-brightstar:
	@printf "\033[1m\033[32m▶ Switching mac-brightstar (local)…\033[0m\n"
	sudo SSH_AUTH_SOCK=$$SSH_AUTH_SOCK darwin-rebuild switch --flake .#mac-brightstar --override-input vantage git+ssh://git@github.com/GDR/vantage

# ── NixOS hosts (SSH + nixos-rebuild) ─────────────────────────────────────────
# SSH into the remote host, pull latest config, and nixos-rebuild switch.
# Each host has DOTFILES_DIR set in its NixOS config.
# Hosts that need infra override vantage with the real private repo.
nix-oldstar:
	@printf "\033[1m\033[32m▶ Rebuilding nix-oldstar…\033[0m\n"
	ssh -t nix-oldstar 'cd $${DOTFILES_DIR:-$$HOME/Workspaces/gdr/dot} && git pull && sudo SSH_AUTH_SOCK=$$SSH_AUTH_SOCK nixos-rebuild switch --flake .#nix-oldstar --override-input vantage git+ssh://git@github.com/GDR/vantage'

nix-goldstar:
	@printf "\033[1m\033[32m▶ Rebuilding nix-goldstar…\033[0m\n"
	ssh -t nix-goldstar 'cd $${DOTFILES_DIR:-$$HOME/Workspaces/gdr/dot} && git pull && sudo nixos-rebuild switch --flake .#nix-goldstar'

# ── Maintenance ───────────────────────────────────────────────────────────────
update:
	@printf "\033[1m\033[32m▶ Updating flake inputs…\033[0m\n"
	nix flake update

fmt:
	@printf "\033[1m\033[32m▶ Formatting Nix files…\033[0m\n"
	nix run nixpkgs#nixpkgs-fmt -- **/*.nix

check:
	@printf "\033[1m\033[32m▶ Running nix flake check…\033[0m\n"
	nix flake check
