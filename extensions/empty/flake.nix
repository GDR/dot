{
  description = "Default empty private extension stub for dot";

  outputs = { self }: {
    dotExtension = {
      features = [ ];
      systemModules = {
        all = [ ];
        linux = [ ];
        darwin = [ ];
      };
      hosts = { };
    };
  };
}
