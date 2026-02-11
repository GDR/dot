# Override Ollama to specific version
final: prev: {
  ollama = prev.ollama.overrideAttrs (_oldAttrs: {
    version = "0.11.3";
    src = final.fetchFromGitHub {
      owner = "ollama";
      repo = "ollama";
      rev = "v0.11.3";
      hash = "sha256-FghgCtVQIxc9qB5vZZlblugk6HLnxoT8xanZK+N8qEc=";
    };
    vendorHash = "sha256-SlaDsu001TUW+t9WRp7LqxUSQSGDF1Lqu9M1bgILoX4=";
  });
}
