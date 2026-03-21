# ──────────────────────────────────────────────────────────────────────────────
# dot — host management
#
#   make update          Update all flake inputs (lock file)
#   make fmt             Format all Nix files
#   make check           Validate deploy-rs schema  (nix flake check)
#
#   make all             Switch all reachable hosts
#   make mac-brightstar  Switch the local Mac (darwin-rebuild)
#   make nix-oldstar     Deploy nix-oldstar via deploy-rs
#   make nix-goldstar    Deploy nix-goldstar via deploy-rs
#   make nixos           Deploy all NixOS hosts
#   make darwin          Switch all Darwin hosts
# ──────────────────────────────────────────────────────────────────────────────

.DEFAULT_GOAL := help
.PHONY: help all update fmt check \
        mac-brightstar \
        nix-oldstar nix-goldstar \
        nixos darwin

# ── Tool resolution ───────────────────────────────────────────────────────────
# Prefer a globally installed `deploy`; fall back to the one in this flake.
DEPLOY := $(shell command -v deploy 2>/dev/null || echo "nix run .#deploy-rs --")

# ── Help ──────────────────────────────────────────────────────────────────────
help:
	@printf "\n  \033[1mdot — host management\033[0m\n\n"
	@printf "  \033[36mmake all\033[0m            Switch / deploy every host\n"
	@printf "  \033[36mmake darwin\033[0m         Switch all Darwin (macOS) hosts\n"
	@printf "  \033[36mmake nixos\033[0m          Deploy all NixOS hosts via deploy-rs\n"
	@printf "\n"
	@printf "  \033[36mmake mac-brightstar\033[0m darwin-rebuild switch for mac-brightstar (this machine)\n"
	@printf "  \033[36mmake nix-oldstar\033[0m    deploy-rs switch for nix-oldstar\n"
	@printf "  \033[36mmake nix-goldstar\033[0m   deploy-rs switch for nix-goldstar\n"
	@printf "\n"
	@printf "  \033[36mmake update\033[0m         nix flake update (refresh lock file)\n"
	@printf "  \033[36mmake fmt\033[0m            nixpkgs-fmt on all *.nix files\n"
	@printf "  \033[36mmake check\033[0m          nix flake check (validates deploy-rs schema)\n"
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
	sudo darwin-rebuild switch --flake .#mac-brightstar

# ── NixOS hosts (deploy-rs) ───────────────────────────────────────────────────
# remoteBuild = true is set in flake.nix, so the build happens on the target
# host itself — no cross-compilation, no copying huge closures from the Mac.
nix-oldstar:
	@printf "\033[1m\033[32m▶ Deploying nix-oldstar…\033[0m\n"
	$(DEPLOY) .#nix-oldstar

nix-goldstar:
	@printf "\033[1m\033[32m▶ Deploying nix-goldstar…\033[0m\n"
	$(DEPLOY) .#nix-goldstar

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
