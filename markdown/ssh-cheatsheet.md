# SSH Cheat Sheet

> **The Ultimate SSH Reference Guide** - Master SSH basics to advanced techniques for secure remote server management

## 📚 Table of Contents

### [Part 1: SSH Basics](#part-1-ssh-basics-for-everyone)
- [Basic SSH Usage](#basic-ssh-usage)
- [SSH with Custom Port & User](#ssh-with-custom-port--user)
- [SSH Key Authentication](#ssh-key-authentication)
- [SSH Config File Tricks](#ssh-config-file-tricks-highly-recommended)
- [SSH Tunneling & Port Forwarding](#ssh-tunneling--port-forwarding)
- [Copy Files with SCP & RSYNC](#copy-files-with-scp--rsync)
- [Debugging SSH Connections](#debugging-ssh-connections)
- [Security Best Practices](#security-best-practices)

### [Part 2: SSH Options Explained](#part-2-ssh-options-explained-beginner--advanced)
- [Understanding SSH Command Syntax](#understanding-ssh-command-syntax)
- [Connection & Authentication Options](#connection--authentication-options)
- [Debugging & Verbose Options](#debugging--verbose-options)
- [Port Forwarding Options](#port-forwarding-options)
- [Jump Hosts & Bastion Servers](#jump-hosts--bastion-servers)
- [Session & Terminal Control](#session--terminal-control)
- [Security & Authentication Options](#security--authentication-options)
- [Networking & Advanced Routing Options](#networking--advanced-routing-options)
- [Encryption & Algorithm Options](#encryption--algorithm-options)
- [ControlMaster & Connection Reuse](#controlmaster--connection-reuse)

---

## Part 1: SSH Basics (For Everyone)

### Basic SSH Usage

| Command | Description |
|---------|-------------|
| `ssh user@server_ip` | Connect to remote server using default port 22 |
| `ssh hostname` | Uses values from `~/.ssh/config` if defined |

```bash
# Basic connection
ssh user@192.168.1.100

# Connect using hostname (requires config)
ssh web-server
```

### SSH With Custom Port & User

| Command | Description |
|---------|-------------|
| `ssh -p 2222 user@server_ip` | Connect to non-standard SSH port |
| `ssh user@hostname` | Login with specific user |

```bash
# Custom port (useful when SSH runs on different port)
ssh -p 2222 user@server_ip

# Explicit user specification
ssh -l postgres server_ip
# Same as: ssh postgres@server_ip
```

### SSH Key Authentication

#### Generate SSH Key

```bash
# Generate ED25519 key (recommended)
ssh-keygen -t ed25519

# Generate RSA key (legacy compatibility)
ssh-keygen -t rsa -b 4096
```

#### Copy Public Key to Server

```bash
# Copy key to remote server
ssh-copy-id user@server_ip

# Manual method
cat ~/.ssh/id_ed25519.pub | ssh user@server_ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

> **🎯 Pro Tip:** After copying your public key, password login is no longer required!

### SSH Config File Tricks *(Highly Recommended)*

Create or edit your SSH config file:

```bash
nano ~/.ssh/config
```

#### Example Configuration

```bash
# Production Database
Host prod-db
    HostName 10.10.10.20
    User postgres
    Port 22
    IdentityFile ~/.ssh/id_ed25519

# Web Server
Host web-prod
    HostName web.example.com
    User deploy
    Port 22
    IdentityFile ~/.ssh/prod_key

# Staging Environment
Host staging
    HostName staging.example.com
    User ubuntu
    Port 22
    ForwardAgent yes
```

**Connect with simple commands:**
```bash
ssh prod-db    # Instead of: ssh -p 22 postgres@10.10.10.20
ssh web-prod   # Clean, fast, and mistake-free!
```

> **✨ Benefits:**
> - **Cleaner** - Simple, memorable commands
> - **Faster** - Less typing, fewer mistakes
> - **Secure** - Centralized key management

### SSH Tunneling & Port Forwarding

#### Local Port Forwarding

```bash
# Access remote PostgreSQL locally
ssh -L 5432:localhost:5432 user@server_ip

# Forward multiple ports
ssh -L 8080:localhost:80 -L 5432:localhost:5432 user@server_ip
```

**Use case:** Access remote database services as if they're running locally.

#### Remote Port Forwarding

```bash
# Expose local service to remote machine
ssh -R 9000:localhost:3000 user@server_ip
```

**Use case:** Make your local development server accessible from the internet through a remote server.

#### Dynamic Port Forwarding (SOCKS Proxy)

```bash
# Create SOCKS proxy for secure browsing
ssh -D 8080 user@server_ip
```

**Configure your browser to use:** `localhost:8080` as SOCKS5 proxy

### Copy Files with SCP & RSYNC

#### Basic File Operations

| Method | Command | Use Case |
|--------|---------|----------|
| **SCP** | `scp file.txt user@server:/path/` | Simple file transfers |
| **SCP Directory** | `scp -r mydir user@server:/path/` | Copy directories |
| **RSYNC** | `rsync -avz file.txt user@server:/path/` | **Recommended** - Better sync |

#### RSYNC Examples

```bash
# Sync directory with compression and archive mode
rsync -avz /local/directory/ user@server:/remote/directory/

# Sync with progress and partial transfer
rsync -avzP /local/directory/ user@server:/remote/directory/

# Exclude certain files
rsync -avz --exclude='*.log' /local/directory/ user@server:/remote/directory/
```

> **🎯 RSYNC Advantages:**
> - **Resume interrupted transfers**
> - **Efficient delta transfers**
> - **Better compression**
> - **Preserve file permissions and timestamps**

### Debugging SSH Connections

```bash
# Verbose mode (shows connection steps)
ssh -v user@server_ip

# Even more details (up to -vvv)
ssh -vvv user@server_ip

# Test specific key
ssh -i ~/.ssh/mykey user@server_ip

# Check authentication method
ssh -v user@server_ip 2>&1 | grep "Authenticating"
```

**Common debugging scenarios:**
- **Authentication issues** - Use `-v` to see which keys are tried
- **Connection refused** - Check if SSH service is running on server
- **Permission denied** - Verify key permissions and server configuration

### Security Best Practices

#### Server Configuration (`/etc/ssh/sshd_config`)

```bash
# Disable password authentication (keys only)
PasswordAuthentication no
PermitRootLogin no
Port 2222

# Restrict users
AllowUsers ubuntu,deploy,appuser

# Enable public key authentication
PubkeyAuthentication yes

# Restart SSH service
sudo systemctl restart sshd
```

#### Key Management

```bash
# Set proper key permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Use strong key types
ssh-keygen -t ed25519  # Preferred over RSA

# Add keys to ssh-agent
ssh-add ~/.ssh/id_ed25519
```

#### Additional Security Tools

- **Fail2Ban** - Automatic IP blocking for failed attempts
- **Two-Factor Authentication** - Google Authenticator integration
- **Port Knocking** - Hide SSH port until specific sequence

---

## Part 2: SSH Options Explained (Beginner → Advanced)

### Understanding SSH Command Syntax

**Basic syntax:** `ssh [options] user@host`

- **user** → Remote Linux username
- **host** → Server IP address or hostname  
- **options** → SSH behavior modifiers (explained below)

### Connection & Authentication Options

| Option | Command | Description |
|--------|---------|-------------|
| `-p` | `ssh -p 2222 user@server` | Custom SSH port |
| `-l` | `ssh -l postgres server_ip` | Specify login username |
| `-i` | `ssh -i ~/.ssh/mykey user@server` | Use specific identity file |
| `-F` | `ssh -F myconfig user@server` | Custom config file |

#### Port (`-p`)
```bash
# Default port is 22, often changed for security
ssh -p 2222 user@server

# Think of ports as "door numbers" on the server
```

#### Login Name (`-l`)
```bash
# Explicit user specification
ssh -l postgres server_ip

# Equivalent to:
ssh postgres@server_ip
```

#### Identity File (`-i`)
```bash
# Use specific private key
ssh -i ~/.ssh/production_key user@prod-server

# Useful when managing multiple keys
```

#### Custom Config (`-F`)
```bash
# Use non-default config file
ssh -F ~/.ssh/work_config user@server

# Default config: ~/.ssh/config
```

### Debugging & Verbose Options

| Level | Command | Use Case |
|-------|---------|----------|
| `-v` | `ssh -v user@server` | Basic debugging |
| `-vv` | `ssh -vv user@server` | Detailed debugging |
| `-vvv` | `ssh -vvv user@server` | Maximum detail |

```bash
# Common debugging scenarios:
ssh -v user@server  # See connection steps and authentication attempts
```

**Helps debug:**
- Authentication issues
- Wrong keys being used
- Network connectivity problems

### Port Forwarding Options

| Option | Syntax | Purpose |
|--------|--------|---------|
| `-L` | `ssh -L local_port:remote_host:remote_port` | **Local** forwarding |
| `-R` | `ssh -R remote_port:local_host:local_port` | **Remote** forwarding |
| `-D` | `ssh -D local_port` | **Dynamic** forwarding (SOCKS) |
| `-W` | `ssh -W host:port` | **Forward** stdio |

#### Local Port Forwarding (`-L`)
```bash
# Access remote PostgreSQL locally
ssh -L 5432:localhost:5432 user@remote-server

# Forward to different host on remote network
ssh -L 8080:192.168.1.10:80 user@remote-server
```

**Syntax breakdown:** `-L local_port:remote_host:remote_port`

#### Remote Port Forwarding (`-R`)
```bash
# Expose local web server to remote network
ssh -R 9000:localhost:3000 user@remote-server
```

**Syntax breakdown:** `-R remote_port:local_host:local_port`

#### Dynamic Port Forwarding (`-D`)
```bash
# Create SOCKS proxy
ssh -D 1080 user@server

# Configure applications to use localhost:1080 as proxy
```

### Jump Hosts & Bastion Servers

#### Jump Host (`-J`)
```bash
# Modern way to connect through bastion servers
ssh -J user@jumpserver user@target-server

# Multiple jumps
ssh -J user@jump1,user@jump2 user@target
```

**Benefits over traditional tunneling:**
- Simpler syntax
- Better connection management
- Automatic connection reuse

### Session & Terminal Control

| Option | Command | Purpose |
|--------|---------|---------|
| `-N` | `ssh -N -L 5432:localhost:5432` | No command execution |
| `-T` | `ssh -T user@server` | Disable pseudo-TTY |
| `-t` | `ssh -t user@server "sudo service restart"` | Force TTY allocation |
| `-f` | `ssh -f -N -L 5432:localhost:5432` | Background mode |

#### No Command Execution (`-N`)
```bash
# Open tunnel only, no shell access
ssh -N -L 5432:localhost:5432 user@server
```

#### Disable Pseudo-TTY (`-T`)
```bash
# Used in scripts, no interactive terminal
ssh -T user@server "ls -la"
```

#### Force TTY (`-t`)
```bash
# Required for interactive commands
ssh -t user@server "sudo systemctl restart postgresql"
```

#### Background Mode (`-f`)
```bash
# Run SSH tunnel in background
ssh -f -N -L 5432:localhost:5432 user@server

# Useful for persistent tunnels
```

### Security & Authentication Options

| Option | Command | Purpose |
|--------|---------|---------|
| `-o` | `ssh -o StrictHostKeyChecking=no user@server` | Custom SSH option |
| `-A` | `ssh -A user@server` | Enable agent forwarding |
| `-a` | `ssh -a user@server` | Disable agent forwarding |

#### Custom SSH Options (`-o`)
```bash
# Common options
ssh -o PasswordAuthentication=no user@server
ssh -o ConnectTimeout=5 user@server
ssh -o StrictHostKeyChecking=no user@server
```

#### Agent Forwarding (`-A` / `-a`)
```bash
# Forward local keys to remote server
ssh -A user@jumpserver

# Safer default - disable forwarding
ssh -a user@server
```

> **⚠️ Security Warning:** Be careful with agent forwarding on untrusted servers!

### Networking & Advanced Routing Options

| Option | Command | Purpose |
|--------|---------|---------|
| `-B` | `ssh -B eth0 user@server` | Bind to specific interface |
| `-b` | `ssh -b 192.168.1.10 user@server` | Use specific source address |
| `-w` | `ssh -w 0:0 user@server` | Tunnel device forwarding |

### Encryption & Algorithm Options

| Option | Command | Purpose |
|--------|---------|---------|
| `-c` | `ssh -c aes256-gcm@openssh.com user@server` | Choose cipher |
| `-m` | `ssh -m hmac-sha2-256 user@server` | MAC algorithm |
| `-Q` | `ssh -Q cipher` | Query supported algorithms |

```bash
# List supported algorithms
ssh -Q cipher
ssh -Q mac
ssh -Q kex
ssh -Q key
```

### ControlMaster & Connection Reuse

| Option | Command | Purpose |
|--------|---------|---------|
| `-S` | `ssh -S /tmp/ssh.sock user@server` | Control socket |
| `-O` | `ssh -O exit user@server` | Control existing connection |

#### Connection Sharing
```bash
# Create master connection
ssh -M -S /tmp/ssh.sock user@server

# Use existing connection (faster)
ssh -S /tmp/ssh.sock user@server

# Check connection status
ssh -O check user@server

# Close all connections
ssh -O exit user@server
```

**Benefits:**
- Faster connection establishment
- Reduced server load
- Better resource usage

---

## 🎯 Golden Rules & Pro Tips

### The Golden Rule
> **If an SSH command looks long or scary, move it into `~/.ssh/config` and simplify your life.**

### Best Practices Summary

1. **Always use SSH keys** instead of passwords
2. **Create SSH config** for frequently used servers
3. **Use connection sharing** for multiple simultaneous connections
4. **Enable verbose mode** (`-v`) when debugging
5. **Keep SSH keys secure** with proper permissions
6. **Use jump hosts** instead of complex port forwarding
7. **Monitor SSH logs** for security issues

### Quick Reference Commands

```bash
# Essential connection commands
ssh user@server              # Basic connection
ssh -v user@server           # Verbose mode
ssh -i key user@server       # Use specific key
ssh -p 2222 user@server      # Custom port

# Port forwarding
ssh -L 8080:localhost:80 user@server    # Local forward
ssh -R 9000:localhost:3000 user@server  # Remote forward
ssh -D 1080 user@server                 # Dynamic forward

# Advanced
ssh -J jump user@target               # Jump host
ssh -f -N -L 5432:localhost:5432 user@server  # Background tunnel
```

---

## 📖 Final Thoughts

SSH is more than just a way to log into a server — it's a powerful tool for:

- **Secure remote access** - Encrypted communication
- **Automation** - Scriptable server management  
- **Tunneling** - Secure port forwarding and proxies
- **Debugging** - Troubleshoot network and authentication issues

**Master the basics** to safely manage any Linux system.  
**Master the advanced options** to handle complex setups with confidence.

**Save this cheatsheet** — you'll reference it more often than you think! 🚀