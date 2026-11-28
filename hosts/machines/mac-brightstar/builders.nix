# Remote x86_64-linux Nix builders for mac-brightstar
# Daemon key /etc/nix/brightstar-nixd_id_ed25519 is authorized on builders via charon-key.
_:
let
  mkLinuxBuilder =
    {
      hostName,
      maxJobs,
      speedFactor,
    }:
    {
      inherit hostName maxJobs speedFactor;
      sshUser = "dgarifullin";
      sshKey = "/etc/nix/brightstar-nixd_id_ed25519";
      system = "x86_64-linux";
      protocol = "ssh-ng";
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
    };
in
{
  nix.distributedBuilds = true;
  nix.buildMachines = [
    (mkLinuxBuilder {
      hostName = "nix-goldstar";
      maxJobs = 16;
      speedFactor = 10;
    })
    (mkLinuxBuilder {
      hostName = "nix-oldstar";
      maxJobs = 8;
      speedFactor = 2;
    })
  ];
}
