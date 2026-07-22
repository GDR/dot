# Original User Request

## Initial Request — 2026-07-22T12:24:29+03:00

Investigate and resolve the macOS Touch ID authentication workflow for `gpg-agent` + `pinentry-touchid` to ensure Touch ID fingerprint prompts appear reliably on SSH logins and Git commit signing without falling back to text prompts or silent RAM bypasses.

Working directory: `/Users/dgarifullin/Workspaces/gdr/dot`
Integrity mode: development

## Requirements

### R1. Deep-Dive Log & Keychain Investigation
- Analyze `pinentry-touchid.log` logs, `gpg-agent` Assuan protocol messages, and macOS Keychain Access behavior (`LocalAuthentication` API, SecKeychain).
- Identify why `pinentry-touchid` falls back to `pinentry-mac` text/GUI prompts or fails to trigger Touch ID biometrics.
- Audit `pkgs/pinentry-touchid/default.nix` Go code, Assuan protocol handlers, and macOS entitlement/sandbox requirements.

### R2. End-to-End Touch ID Integration Fix
- Fix `pinentry-touchid` build/code or `gpg-agent` configuration in `modules/home/security/gpg.nix` so Touch ID biometrics trigger reliably when an SSH or GPG key is accessed.
- Ensure Keychain entry creation and retrieval use matching query attributes (`Service`, `Account`, `Label`).
- Ensure fallback to `pinentry-mac` works seamlessly when Touch ID is not used.

### R3. OpenSSH & ControlMaster Integration
- Ensure OpenSSH `ControlMaster` settings (`ssh.nix`) do not conceal authentication failures or bypass `IdentityAgent` queries.
- Ensure `SSH_AUTH_SOCK` environment variable is exported reliably across all zsh sessions and subshells.

### R4. Automated Testing & Verification
- Create an automated test or diagnostic script that verifies `pinentry-touchid` self-test, Keychain item storage, and `gpg-agent` Touch ID prompt invocation.

## Acceptance Criteria

### Diagnostics & Code Quality
- [ ] `/etc/profiles/per-user/dgarifullin/bin/pinentry-touchid -self-test` passes with 0 errors.
- [ ] `nix flake check` passes 100% cleanly.

### Touch ID Verification
- [ ] Running a fresh `gpgconf --kill gpg-agent && ssh-add ~/.ssh/mac_brightstar_ed25519` or `gpg --clearsign` triggers a Touch ID fingerprint prompt.
- [ ] Passphrases stored in Keychain are correctly retrieved via Touch ID authorization (`authFn`).
