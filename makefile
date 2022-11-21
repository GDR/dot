all: 
	$(MAKE) switch-nix 
	$(MAKE) switch-home
switch-nix:
	sudo nixos-rebuild switch --flake .#Nix-Germany
switch-home:
	home-manager switch --flake .#gdr