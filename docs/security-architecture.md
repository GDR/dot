# Security Architecture

Overview of the security design, key management, authentication agent architecture, and secret management across NixOS and macOS (`mac-brightstar`) hosts in `GDR/dot`.

---

## Architecture Overview

```
                          ┌──────────────────────────┐
                          │     User Operations      │
                          │ (git, ssh, sops, rebase) │
                          └─────────────┬────────────┘
                                        │
                                        ▼
                          ┌──────────────────────────┐
                          │    SSH_AUTH_SOCK / GPG   │
                          │ (~/.gnupg/S.gpg-agent.ssh│
                          └─────────────┬────────────┘
                                        │
                                        ▼
                          ┌──────────────────────────┐
                          │        gpg-agent         │
                          │   (RAM Cache: 10 mins)   │
                          └─────────────┬────────────┘
                                        │
                    ┌───────────────────┴───────────────────┐
                    ▼                                       ▼
        ┌──────────────────────┐                ┌──────────────────────┐
        │     macOS Darwin     │                │     Linux NixOS      │
        │    (pinentry-mac /   │                │   (pinentry-curses)  │
        │   pinentry-touchid   │                │                      │
        │   Keychain Sync)     │                │                      │
        └──────────────────────┘                └──────────────────────┘
```

---

## 1. Authentication & Agent Architecture (`gpg-agent`)

The dotfiles repository uses **`gpg-agent` with SSH support** as the unified agent across macOS and Linux:

* **Unified Agent**: `services.gpg-agent` with `enableSshSupport = true` acts as both the OpenPGP agent and the OpenSSH Agent (`SSH_AUTH_SOCK="$HOME/.gnupg/S.gpg-agent.ssh"`).
* **Biometric & Keychain Integration (macOS)**: Uses `pinentry_mac` (or `pinentry-touchid`). Passphrases can be saved in macOS Keychain, allowing Touch ID / system prompt authorization.
* **Smart RAM Caching (`defaultCacheTtl = 600`)**: Key passphrases are cached in memory for **10 minutes** after your first authorization. This enables multi-commit operations (`git rebase -i`, `git fetch --all`, `git submodule`) to sign 50+ commits instantly without prompting for your passphrase/fingerprint on every single commit.
* **Terminal Pinentry (Linux)**: Uses `pinentry-curses` for headless or terminal environments.

---

## 2. Git Commit Signing

Git commit signing is configured via `modules/systems/all/shell/git.nix` and `modules/home/security/gpg.nix`:

* **OpenPGP & SSH Signing Formats**: Supports both OpenPGP (`gpg.format = "openpgp"`) and SSH signing (`gpg.format = "ssh"`).
* **Automatic Agent Signing**: Git routes signing requests to `gpg-agent`, which retrieves the cached key passphrase or prompts `pinentry-mac`.

---

## 3. Secret Management (`sops-nix`)

Secrets (SOPS encrypted files in `hosts/machines/<host>/secrets/`) are managed using **`sops-nix`** and **`age`**:

* **Key Derivation**: `sops-nix` uses `ssh-to-age` to convert `Ed25519` SSH public keys into `age` recipient public keys (`age1...`).
* **Host Keys**: NixOS hosts decrypt system secrets at boot using `/etc/ssh/ssh_host_ed25519_key`.
* **User Keys (macOS)**: macOS user secrets are decrypted using `~/.ssh/id_ed25519` or `~/.config/sops/age/keys.txt`.

---

## 4. SSH Connection Multiplexing (`ControlMaster`)

To prevent multiple SSH connection handshakes:

* **Multiplexing Config**: Enabled under `Host *` in `modules/home/shell/ssh/ssh.nix`:
  ```ssh
  Host *
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h:%p
    ControlPersist 3m
    IdentitiesOnly yes
  ```
* **Behavior**: The first SSH connection to a host (e.g. `nix-oldstar` or `github.com`) establishes a master control socket in `~/.ssh/sockets/`. Subsequent connections reuse the active socket for 3 minutes without requiring a new SSH handshake.
