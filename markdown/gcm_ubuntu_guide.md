# Git Credential Manager Setup Guide
**Platform:** Ubuntu / Linux Mint  
**Purpose:** Automated GitHub authentication via stored credentials

---

## Credential Helper Comparison

### Git Credential Manager (GCM) - **RECOMMENDED**
- **Pros:** Cross-platform, OAuth support, secure system keyring integration, active Microsoft maintenance
- **Cons:** Requires .NET runtime (handled automatically)
- **Best for:** Enterprise environments, multiple Git providers (GitHub, Azure DevOps, GitLab)

### Alternative: libsecret
- **Pros:** Native Linux tool, lightweight, no external dependencies
- **Cons:** Basic auth only (PAT required), manual token management
- **Best for:** Simple workflows, single provider setups

### Not Recommended: cache/store
- **cache:** Credentials timeout (default 15 min)
- **store:** Plain-text file storage (insecure)

---

## Installation Instructions

### Step 1: Download and Install GCM

```bash
# Download latest GCM for Debian-based systems (check releases page for current version)
# Visit: https://github.com/git-ecosystem/git-credential-manager/releases
# Download link format example:
wget https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.6.0/gcm-linux_amd64.2.6.0.deb

# Or use this one-liner to always get the latest version:
wget $(curl -s https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest | grep "gcm-linux_amd64.*\.deb" | cut -d '"' -f 4)

# Install the package
sudo dpkg -i gcm-linux_amd64.*.deb

# Verify installation
git-credential-manager --version
```

**Expected output:** `git-credential-manager 2.6.0+<hash>`

---

## Configuration Commands

### Step 2: Configure Git to Use GCM

```bash
# Set GCM as the global credential helper
git config --global credential.helper manager

# Configure GitHub.com provider explicitly
git config --global credential.https://github.com.provider github

# Set credential storage backend to use system keyring (GNOME Keyring/KWallet)
git config --global credential.credentialStore secretservice

# Enable Git credential caching for GCM (optional, recommended)
git config --global credential.guiPrompt false
```

### Step 3: Configure Azure DevOps (if needed)

```bash
# Set Azure DevOps provider
git config --global credential.https://dev.azure.com.provider azure-repos
```

---

## Best Practice Configuration

### Recommended `.gitconfig` Settings

Add these to your `~/.gitconfig` or run as commands:

```bash
# Core credential settings
git config --global credential.helper manager
git config --global credential.credentialStore secretservice

# Provider-specific settings
git config --global credential.https://github.com.provider github
git config --global credential.https://dev.azure.com.provider azure-repos

# Authentication preferences
git config --global credential.guiPrompt false
git config --global credential.interactive auto

# GitHub-specific OAuth flow
git config --global credential.https://github.com.useHttpPath false
```

### Your Complete `.gitconfig` Credential Section

```ini
[credential]
    helper = manager
    credentialStore = secretservice
    guiPrompt = false
    interactive = auto

[credential "https://github.com"]
    provider = github
    useHttpPath = false

[credential "https://dev.azure.com"]
    provider = azure-repos
```

---

## Credential Store Options

### `secretservice` (RECOMMENDED for Ubuntu/Linux Mint)

```bash
git config --global credential.credentialStore secretservice
```

- **Storage:** GNOME Keyring (Ubuntu) / KDE Wallet (if using KDE)
- **Security:** Encrypted system keyring with OS-level protection
- **Best for:** Desktop environments with GUI

### `gpg` (Alternative for advanced users)

```bash
git config --global credential.credentialStore gpg
```

- **Storage:** GPG-encrypted files
- **Security:** Requires GPG key setup
- **Best for:** Servers or users already using GPG

### `plaintext` (NOT RECOMMENDED)

```bash
git config --global credential.credentialStore plaintext
```

- **Storage:** `~/.gcm/store` in plain text
- **Security:** None - credentials visible in filesystem
- **Use case:** Testing only, never for production

---

## First-Time Authentication

### Step 4: Trigger Authentication

Perform any Git operation requiring authentication:

```bash
# Clone a private repository
git clone https://github.com/your-org/your-private-repo.git

# Or push to an existing repository
cd /path/to/your/repo
git push origin main
```

**What happens:**
1. GCM detects authentication is needed
2. Opens your default browser for GitHub OAuth
3. You authorize the application
4. Credentials stored securely in system keyring
5. All future operations use stored credentials automatically

---

## Verification Steps

### Step 5: Verify Configuration

```bash
# Check credential helper is set
git config --global --get credential.helper

# Check credential store backend
git config --global --get credential.credentialStore

# Check GitHub provider
git config --global --get credential.https://github.com.provider

# List all credential settings
git config --global --get-regexp credential
```

**Expected output:**
```
credential.helper manager
credential.credentialStore secretservice
credential.https://github.com.provider github
```

### Step 6: Test Stored Credentials

```bash
# Perform a second Git operation - should NOT prompt for credentials
git pull origin main
```

If no authentication prompt appears, credentials are stored successfully.

---

## Troubleshooting

### GCM Not Found After Installation

```bash
# Add GCM to PATH (add to ~/.bashrc)
export PATH="$PATH:/usr/local/bin"
source ~/.bashrc
```

### Keyring Service Not Available

```bash
# Install GNOME Keyring (if missing)
sudo apt update
sudo apt install gnome-keyring libsecret-1-0

# For headless/server environments, use gpg instead
git config --global credential.credentialStore gpg
```

### Clear Stored Credentials (if needed)

```bash
# Remove all stored credentials
git-credential-manager erase

# Remove specific GitHub credentials
printf "protocol=https\nhost=github.com\n" | git-credential-manager erase
```

### Reconfigure GCM

```bash
# Uninstall current configuration
git-credential-manager unconfigure

# Reinstall configuration
git-credential-manager configure
```

---

## Multi-Account Setup

### Different Credentials per Repository

For repositories requiring different GitHub accounts:

```bash
# Navigate to specific repository
cd /path/to/specific/repo

# Set credential helper for this repo only (overrides global)
git config credential.https://github.com.username your-alternate-username

# Set to use HTTP path for account isolation
git config credential.https://github.com.useHttpPath true
```

---

## Terminal Environment Support

### Works in All Your Environments

- **Kiro-CLI:** Full support
- **VSCode Integrated Terminal:** Full support
- **Warp Terminal:** Full support
- **Standard Bash:** Full support

GCM operates at the Git level, independent of terminal emulator.

---

## Quick Reference Card

```bash
# Installation (get latest from releases page or use auto-fetch)
wget $(curl -s https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest | grep "gcm-linux_amd64.*\.deb" | cut -d '"' -f 4)
sudo dpkg -i gcm-linux_amd64.*.deb

# Essential Configuration
git config --global credential.helper manager
git config --global credential.credentialStore secretservice
git config --global credential.https://github.com.provider github

# Verification
git config --global --get-regexp credential

# First Use
git clone https://github.com/your-org/your-repo.git
# (Browser opens for OAuth, authenticate once)

# Clear Credentials
git-credential-manager erase
```

---

## Next Steps

1. **Install GCM** using the dpkg command above
2. **Run the four essential configuration commands** under "Step 2"
3. **Perform a Git clone/push** to trigger first authentication
4. **Verify** no re-authentication required on second operation
5. **Add to team documentation** for consistent setup across engineers

---

**Last Updated:** January 2026  
**GCM Version:** 2.6.0  
**Supported Platforms:** Ubuntu 20.04+, Linux Mint 20+