{
  description = "Stub for GDR/vantage — used on machines that don't need infra modules";

  inputs = { };

  outputs = { self, ... }: {
    nixosModules = {
      infra-server = { lib, ... }:
        let inherit (lib) mkOption types mkEnableOption; in {
          options.services.vantage = {
            consul = {
              enable = mkEnableOption "Consul (stub)";
              mode = mkOption { type = types.str; default = ""; };
              datacenter = mkOption { type = types.str; default = ""; };
              enableUi = mkOption { type = types.bool; default = false; };
              gossipKeyFile = mkOption { type = types.nullOr types.path; default = null; };
            };
            nomad = {
              enable = mkEnableOption "Nomad (stub)";
              server = mkOption { type = types.bool; default = false; };
              client = mkOption { type = types.bool; default = false; };
              datacenter = mkOption { type = types.str; default = ""; };
              gossipKeyFile = mkOption { type = types.nullOr types.path; default = null; };
            };
          };
        };
      consul-dns = { lib, ... }:
        let inherit (lib) mkOption types mkEnableOption; in {
          options.services.vantage.consul-dns = {
            enable = mkEnableOption "Consul DNS (stub)";
            nameserver = mkOption { type = types.str; default = "127.0.0.1"; };
          };
        };
      remote-builder = { ... }: { };
    };
    darwinModules = {
      consul-dns = { lib, ... }:
        let inherit (lib) mkOption types mkEnableOption; in {
          options.services.vantage.consul-dns = {
            enable = mkEnableOption "Consul DNS (stub)";
            nameserver = mkOption { type = types.str; default = "127.0.0.1"; };
          };
        };
    };
  };
}
