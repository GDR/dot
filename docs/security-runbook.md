# Security & Key Management Runbook

Step-by-step guides for frequent security, key management, and secret operations in `GDR/dot`.

---

## 1. Adding an SSH Key to `gpg-agent`

When `SSH_AUTH_SOCK` points to `~/.gnupg/S.gpg-agent.ssh`:

1. **Add your SSH key**:
   ```bash
   ssh-add ~/.ssh/id_ed25519
   ```
2. **Verify loaded keys**:
   ```bash
   ssh-add -l
   ```

---

## 2. Setting Up GPG Commit Signing

### Step 1: Generate or Import a GPG Key
* **Generate a new key**:
  ```bash
  gpg --full-generate-key
  ```
* **Import an existing key**:
  ```bash
  gpg --import /path/to/private-key.asc
  ```

### Step 2: Find Your Key ID
```bash
gpg --list-secret-keys --keyid-format=long
```
Look for the `sec` line: `sec ed25519/3AA5C34371567BD2 ...` -> Key ID is `3AA5C34371567BD2`.

### Step 3: Configure Git
```bash
git config --global user.signingkey 3AA5C34371567BD2
git config --global gpg.format openpgp
git config --global commit.gpgSign true
```

---

## 3. Adding a New Key for SOPS Secret Encryption

To allow a new SSH key to decrypt/encrypt SOPS secrets:

1. **Convert SSH public key to Age format**:
   ```bash
   nix-shell -p ssh-to-age --run "ssh-to-age < ~/.ssh/id_ed25519.pub"
   ```
   *(Output: `age1wa37p3gvk7p0m0rwzg43xlnhdm75...`)*

2. **Add to `.sops.yaml`**:
   Edit [.sops.yaml](file:///Users/dgarifullin/Workspaces/gdr/dot/.sops.yaml) under `creation_rules`:
   ```yaml
   creation_rules:
     - path_regex: hosts/machines/mac-brightstar/secrets/.*
       age:
         - age1wa37p3gvk7p0m0rwzg43xlnhdm75...
   ```

3. **Update existing secrets**:
   ```bash
   sops updatekeys hosts/machines/mac-brightstar/secrets/<secret-name>.yaml
   ```

---

## 4. Authorizing SSH Access to Remote Machines (`nix-oldstar`)

### Option A: Via Nix Host Configuration (Recommended)
Add your public key to `keys` in `hosts/machines/nix-oldstar/default.nix`:
```nix
hostUsers.dgarifullin = userDefaults.user // {
  enable = true;
  keys = [
    {
      name = "brightstar";
      type = "ed25519";
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...";
      purpose = [ "ssh" ];
    }
  ];
};
```

### Option B: Quick Manual Copy
```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub dgarifullin@nix-oldstar
```

---

## 5. Troubleshooting & Maintenance

### Restarting `gpg-agent` (Clearing RAM Cache)
If you want to flush cached passphrases immediately:
```bash
gpgconf --kill gpg-agent
```

### Closing Active SSH ControlMaster Multiplexing Sockets
If an SSH connection is stuck or you want to force a fresh connection:
```bash
ssh -O exit nix-oldstar
```

### Checking Active SSH Sockets
```bash
ls -la ~/.ssh/sockets/
```
