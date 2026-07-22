# 🛡️ Security Architecture

Comprehensive guide to key management, authentication agent architecture, secret decryption, and SSH multiplexing across NixOS and macOS hosts in `GDR/dot`.

---

## 📐 System Architecture

The dotfiles repository uses a **unified `gpg-agent` architecture** across both macOS (`mac-brightstar`) and Linux (`nix-goldstar`, `nix-oldstar`).

```mermaid
flowchart TD
    subgraph Operations [" User Operations "]
        GitCommit["git commit / git rebase"]
        SSHConn["ssh host / git push"]
        SOPSDecrypt["sops / sops-nix"]
    end

    subgraph Agent [" Unified Agent Layer "]
        GPGAgent["gpg-agent\n(SSH_AUTH_SOCK = ~/.gnupg/S.gpg-agent.ssh)"]
        RAMCache["10-Minute RAM Cache\n(defaultCacheTtl = 600s)"]
    end

    subgraph Pinentry [" Platform Auth Providers "]
        MacPinentry["macOS: pinentry_mac\n(Keychain Integration / Touch ID)"]
        LinuxPinentry["Linux: pinentry-curses\n(Terminal TTY Prompt)"]
    end

    subgraph Storage [" Key Stores & Cryptography "]
        GPGStore["~/.gnupg/\n(OpenPGP / SSH Keys)"]
        AgeStore["ssh-to-age\n(~/.ssh/id_ed25519 -> age1...)"]
    end

    GitCommit --> GPGAgent
    SSHConn --> GPGAgent
    SOPSDecrypt --> AgeStore

    GPGAgent <--> RAMCache
    GPGAgent <--> MacPinentry
    GPGAgent <--> LinuxPinentry
    GPGAgent <--> GPGStore

    style Operations fill:#1e1e2e,stroke:#89b4fa,stroke-width:2px,color:#cdd6f4
    style Agent fill:#181825,stroke:#f9e2af,stroke-width:2px,color:#cdd6f4
    style Pinentry fill:#181825,stroke:#a6e3a1,stroke-width:2px,color:#cdd6f4
    style Storage fill:#181825,stroke:#cba6f7,stroke-width:2px,color:#cdd6f4
```

---

## 🔑 Core Security Subsystems

### 1. Unified Authentication Agent (`gpg-agent`)

> [!NOTE]
> Single daemon managing both OpenPGP commit signing and OpenSSH authentication.

| Component | Configuration | Purpose |
| :--- | :--- | :--- |
| **Agent Daemon** | `services.gpg-agent.enable = true` | Manages private keys in memory. |
| **SSH Emulation** | `services.gpg-agent.enableSshSupport = true` | Exposes `~/.gnupg/S.gpg-agent.ssh` for SSH. |
| **Cache TTL** | `defaultCacheTtl = 600` (10 mins) | Eliminates repetitive prompts during multi-commit rebases. |
| **Max TTL** | `maxCacheTtl = 7200` (2 hours) | Hard upper bound before re-authentication. |

---

### 2. Authentication Flow & Caching

The diagram below illustrates how `gpg-agent` handles authentication during interactive commands versus cached sub-ops:

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 Developer
    participant Git as 📦 Git / SSH Client
    participant Agent as 🛡️ gpg-agent (RAM)
    participant Pinentry as 🔐 pinentry_mac / Keychain
    participant Remote as 🌐 Remote Host / GitHub

    User->>Git: git rebase -i / git commit
    Git->>Agent: Request Signature / Auth
    alt Passphrase Cached in RAM (< 10 mins)
        Agent-->>Git: Return Signature instantly (0 prompts)
    else Cache Expired / First Request
        Agent->>Pinentry: Request Passphrase / Touch ID
        Pinentry->>User: Display GUI / Keychain Prompt
        User-->>Pinentry: Authorize / Touch ID
        Pinentry-->>Agent: Passphrase Authorized
        Agent->>Agent: Store in RAM Cache (600s)
        Agent-->>Git: Return Signature
    end
    Git->>Remote: Complete SSH / Signed Push
```

---

### 3. Secret Management (`sops-nix` & `ssh-to-age`)

> [!IMPORTANT]
> `sops-nix` encrypts repository secrets using `age` public keys derived directly from `Ed25519` SSH keys.

```mermaid
flowchart LR
    SSHKey["~/.ssh/id_ed25519.pub\n(Ed25519 Public Key)"]
    Converter["ssh-to-age"]
    AgeKey["age1wa37p3gvk7p0m0rwzg43xlnhdm75...\n(Age Recipient Key)"]
    SopsYaml[".sops.yaml\n(Creation Rules)"]
    EncryptedSecrets["hosts/machines/<host>/secrets/\n(SOPS Encrypted YAML)"]

    SSHKey --> Converter --> AgeKey --> SopsYaml --> EncryptedSecrets

    style SSHKey fill:#1e1e2e,stroke:#89b4fa,color:#cdd6f4
    style Converter fill:#313244,stroke:#f9e2af,color:#cdd6f4
    style AgeKey fill:#181825,stroke:#a6e3a1,color:#cdd6f4
    style SopsYaml fill:#181825,stroke:#cba6f7,color:#cdd6f4
    style EncryptedSecrets fill:#181825,stroke:#f38ba8,color:#cdd6f4
```

---

### 4. SSH Connection Multiplexing (`ControlMaster`)

> [!TIP]
> Connection multiplexing reuses a single TCP tunnel for multiple connections to the same host within 3 minutes.

```mermaid
sequenceDiagram
    autonumber
    participant Client as 💻 Terminal Process
    participant OpenSSH as 🔒 OpenSSH Engine
    participant Socket as 🔌 ~/.ssh/sockets/git@github.com:22
    participant Remote as 🐙 GitHub / Remote Server

    Note over Client,Remote: Connection 1: Initial SSH / Git Fetch
    Client->>OpenSSH: ssh -T git@github.com
    OpenSSH->>Remote: Perform SSH Handshake & Agent Auth
    OpenSSH->>Socket: Create Master Control Socket
    Remote-->>Client: Authenticated Session Established

    Note over Client,Remote: Connection 2..N: Submodules / Parallel Fetch (< 3 mins)
    Client->>OpenSSH: git submodule update / git fetch
    OpenSSH->>Socket: Re-use Active Master Control Socket
    Socket-->>Client: Session Connected Instantly (0 Handshakes / 0 Prompts!)
```

| Directive | Value | Purpose |
| :--- | :--- | :--- |
| `ControlMaster` | `auto` | Automatically creates a master connection if none exists. |
| `ControlPath` | `~/.ssh/sockets/%r@%h:%p` | Path template for control sockets (`0700` permissions). |
| `ControlPersist` | `3m` | Keeps background connection alive for 3 minutes after idle. |
| `IdentitiesOnly` | `yes` | Restricts key offerings to explicitly defined `IdentityFile` entries. |
