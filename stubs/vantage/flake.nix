{
  description = "Stub for GDR/vantage — used on machines that don't need infra modules";

  inputs = { };

  outputs = { self, ... }: {
    nixosModules = {
      infra-server = { ... }: { };
      consul-dns = { ... }: { };
      remote-builder = { ... }: { };
    };
    darwinModules = {
      consul-dns = { ... }: { };
    };
  };
}
