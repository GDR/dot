{
  lib,
  writeShellApplication,
  python3,
  git,
  cacert,
}:

writeShellApplication {
  name = "detached-repo-sync";

  runtimeInputs = [
    python3
    git
  ];

  runtimeEnv = {
    GIT_SSL_CAINFO = "${cacert}/etc/ssl/certs/ca-bundle.crt";
    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  };

  text = ''
    exec "${lib.getExe python3}" -B "${./detached_repo_sync.py}" "$@"
  '';

  meta = {
    description = "Sync and fan-out helper for detached Git repositories";
    mainProgram = "detached-repo-sync";
    platforms = lib.platforms.unix;
  };
}
