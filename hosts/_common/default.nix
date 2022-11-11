{ inputs, config, lib, ... }:
{
  imports = [ 
    ./nix.nix
    # ./desktop
    ./xserver.nix
  ];

  # Enable networking
  networking.networkmanager.enable = true;
  
  sound.enable = true;

  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh = {
    enable = true;
    # Forbid root login through SSH.
    permitRootLogin = "no";
    # Use keys only. Remove if you want to SSH using password (not recommended)
    passwordAuthentication = false;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.05";
}