# ──────────────────────────────────────────────────────────────────────────────
# dot — host management
#
#   just update          Update all flake inputs (lock file)
#   just fmt             Format all Nix files
#   just check           nix flake check
#
#   just all             Switch all reachable hosts
#   just mac-brightstar  Switch the local Mac (darwin-rebuild)
#   just nix-oldstar     Rebuild nix-oldstar via SSH + nixos-rebuild
#   just nix-goldstar    Rebuild nix-goldstar via SSH + nixos-rebuild
#   just nixos           Rebuild all NixOS hosts
#   just darwin          Switch all Darwin hosts
# ──────────────────────────────────────────────────────────────────────────────

# Optional private extension path override (set DOT_PRIVATE_EXTENSION=/path/to/dot-private)
private_ext := env("DOT_PRIVATE_EXTENSION", "")
private_override := if private_ext != "" { "--override-input private-extension path:" + private_ext } else { "" }

# ── Help ──────────────────────────────────────────────────────────────────────
[doc('Show available recipes')]
help:
	@printf "\n  \033[1mdot — host management\033[0m\n\n"
	@printf "  \033[36mjust all\033[0m            Switch / deploy every host\n"
	@printf "  \033[36mjust darwin\033[0m         Switch all Darwin (macOS) hosts\n"
	@printf "  \033[36mjust nixos\033[0m          Rebuild all NixOS hosts via SSH\n"
	@printf "\n"
	@printf "  \033[36mjust mac-brightstar\033[0m darwin-rebuild switch for mac-brightstar (this machine)\n"
	@printf "  \033[36mjust nix-oldstar\033[0m    nixos-rebuild switch for nix-oldstar (remote)\n"
	@printf "  \033[36mjust nix-goldstar\033[0m   nixos-rebuild switch for nix-goldstar (remote)\n"
	@printf "\n"
	@printf "  \033[36mjust update\033[0m         nix flake update (refresh lock file)\n"
	@printf "  \033[36mjust fmt\033[0m            nixpkgs-fmt on all *.nix files\n"
	@printf "  \033[36mjust fmt-check\033[0m      Check formatting without modifying files\n"
	@printf "  \033[36mjust lint\033[0m           Run deadnix and statix checks\n"
	@printf "  \033[36mjust check-hosts\033[0m    Dry-run build/eval host configurations\n"
	@printf "  \033[36mjust check\033[0m          Composite target (fmt-check + lint + check-hosts + flake check)\n"
	@printf "\n"

# ── Top-level targets ─────────────────────────────────────────────────────────
[doc('Switch / deploy every host')]
all: darwin nixos

[doc('Switch all Darwin (macOS) hosts')]
darwin: mac-brightstar

[doc('Rebuild all NixOS hosts via SSH')]
nixos: nix-oldstar nix-goldstar

# ── Darwin hosts ──────────────────────────────────────────────────────────────
# mac-brightstar is the machine you're usually sitting at, so we run
# darwin-rebuild directly (no SSH needed).
[doc('darwin-rebuild switch for mac-brightstar (local)')]
mac-brightstar:
	@printf "\033[1m\033[32m▶ Switching mac-brightstar (local)…\033[0m\n"
	sudo SSH_AUTH_SOCK=$SSH_AUTH_SOCK darwin-rebuild switch --flake .#mac-brightstar {{private_override}}

# ── NixOS hosts (SSH + nixos-rebuild) ─────────────────────────────────────────
# SSH into the remote host, pull latest config, and nixos-rebuild switch.
# Each host has DOTFILES_DIR set in its NixOS config.
[doc('nixos-rebuild switch for nix-oldstar (remote)')]
nix-oldstar:
	@printf "\033[1m\033[32m▶ Rebuilding nix-oldstar…\033[0m\n"
	ssh -t nix-oldstar 'cd ${DOTFILES_DIR:-$HOME/Workspaces/gdr/dot} && git pull && sudo nixos-rebuild switch --flake .#nix-oldstar ${DOT_PRIVATE_EXTENSION:+--override-input private-extension path:$DOT_PRIVATE_EXTENSION}'

[doc('nixos-rebuild switch for nix-goldstar (remote)')]
nix-goldstar:
	@printf "\033[1m\033[32m▶ Rebuilding nix-goldstar…\033[0m\n"
	ssh -t nix-goldstar 'cd ${DOTFILES_DIR:-$HOME/Workspaces/gdr/dot} && git pull && sudo nixos-rebuild switch --flake .#nix-goldstar ${DOT_PRIVATE_EXTENSION:+--override-input private-extension path:$DOT_PRIVATE_EXTENSION}'

# ── Maintenance ───────────────────────────────────────────────────────────────
[doc('nix flake update (refresh lock file)')]
update:
	@printf "\033[1m\033[32m▶ Updating flake inputs…\033[0m\n"
	nix flake update

[doc('nixpkgs-fmt on all *.nix files')]
fmt:
	@printf "\033[1m\033[32m▶ Formatting Nix files…\033[0m\n"
	nix run nixpkgs#nixpkgs-fmt -- .

[doc('Check formatting without modifying files')]
fmt-check:
	@printf "\033[1m\033[32m▶ Checking Nix formatting…\033[0m\n"
	nix run nixpkgs#nixpkgs-fmt -- --check .

[doc('Run deadnix and statix checks')]
lint:
	@printf "\033[1m\033[32m▶ Running deadnix & statix…\033[0m\n"
	nix run nixpkgs#deadnix -- --fail --no-lambda-pattern-names --no-lambda-arg .
	nix run nixpkgs#statix -- check .

[doc('Dry-run build/eval host configurations')]
check-hosts:
	@printf "\033[1m\033[32m▶ Evaluating system host configurations…\033[0m\n"
	nix build .#nixosConfigurations.nix-goldstar.config.system.build.toplevel --dry-run {{private_override}}
	nix build .#nixosConfigurations.nix-oldstar.config.system.build.toplevel --dry-run {{private_override}}
	nix eval .#darwinConfigurations.mac-brightstar.config.system.build.toplevel.drvPath {{private_override}}

[doc('Composite target (fmt-check + lint + check-hosts + flake check)')]
check: fmt-check lint check-hosts
	@printf "\033[1m\033[32m▶ Running nix flake check…\033[0m\n"
	nix flake check --all-systems {{private_override}}
