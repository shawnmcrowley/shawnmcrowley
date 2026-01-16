## Creating an SSL Configuration for Multiple Apps Routed Securely

### Directory Structure

```bash
your-project/
├── docker-compose.yml
└── traefik/
    ├── traefik.yml          # Static config
    ├── dynamic/
    │   └── dynamic.yml      # Dynamic config (routes/services)
    └── certs/
        ├── localhost.pem    # SSL certificate
        └── localhost-key.pem # SSL private key
```

### Generate SSL Certificates with mkcert

Install mkcert if you haven't already:
- On macOS: `brew install mkcert`
- On Linux: see [mkcert installation](https://github.com/FiloSottile/mkcert#installation)

```bash
# Install the local CA (only once)
mkcert -install

# Create the certs directory
mkdir -p traefik/certs

# Generate certificates for localhost
cd traefik/certs
mkcert -cert-file localhost.pem \
       -key-file localhost-key.pem \
       localhost 127.0.0.1 ::1

# Verify the files were created
ls -la localhost.pem localhost-key.pem

# Restart Traefik
docker-compose restart traefik
```

### Start Everything

```bash
# Create the network (if it doesn't exist)
docker network create traefik-public

# Start Traefik
docker-compose up -d

# Check logs
docker-compose logs -f traefik
```

### Traefik v3 Notes

The configuration works properly with traefik:v3. Key differences:

- Simplified TLS configuration
- Entry point redirections work slightly differently
- The `tls: {}` notation in routers is sufficient for enabling TLS

Verify in logs:
- Loads traefik.yml successfully
- Picks up the dynamic configuration from /etc/traefik/dynamic
- Certificates are found at /certs/localhost.pem

## Browser Validation

### Chrome Green Lock

To see the green lock in Chrome:

1. **Restart Chrome** - Close ALL Chrome windows completely (not just tabs)
2. **Or use Incognito/Private browsing mode** to test immediately
3. **Or clear HSTS cache**:
   - Go to `chrome://net-internals/#hsts`
   - Enter `localhost` in "Delete domain security policies"
   - Click Delete

Since you used `mkcert -install`, the certificate authority is already trusted by your system. Chrome should show the green lock immediately after closing all Chrome instances and visiting https://localhost.

### Verify mkcert CA

```bash
# Verify mkcert CA is installed
mkcert -CAROOT

# Reinstall if needed
mkcert -install
```

Expected output:
```
The local CA is already installed in the system trust store! 👍
The local CA is already installed in the Firefox and/or Chrome/Chromium trust store! 👍
```

## Install on Windows Chrome/Browser

### In WSL

```bash
# Find your CA location
mkcert -CAROOT
# Shows: /home/username/.local/share/mkcert

# Copy the rootCA.pem to a Windows location
cp ~/.local/share/mkcert/rootCA.pem /mnt/c/Users/YourWindowsUsername/Downloads/
```

### In PowerShell

```powershell
# Install the CA
certutil -addstore -f "ROOT" "C:\Users\YourWindowsUsername\Downloads\rootCA.pem"
```

### Alternative Method

```bash
# Copy and rename to .crt extension in WSL
cp ~/.local/share/mkcert/rootCA.pem /mnt/c/Users/scrowley/Downloads/rootCA.crt
```

Or open in Windows Explorer:
```bash
explorer.exe $(wslpath -w ~/.local/share/mkcert)
```

Then in Windows Explorer:
1. Double-click rootCA.crt
2. Click "Install Certificate..."
3. Select "Local Machine" → Next (requires admin)
4. Choose "Place all certificates in the following store" → Browse
5. Select "Trusted Root Certification Authorities" → OK
6. Next → Finish

## Troubleshooting

### Option 1 - Quickest

Open a new Incognito window in Chrome and visit https://localhost.

### Option 2 - Clear Chrome's HSTS Cache

1. Go to `chrome://net-internals/#hsts`
2. Scroll to "Delete domain security policies"
3. Enter `localhost` and click "Delete"
4. Go to `chrome://restart` to restart Chrome
5. Visit https://localhost again

### Option 3 - Full Restart

1. Close ALL Chrome windows completely (check system tray too)
2. Kill remaining Chrome processes: `pkill chrome` or `killall chrome`
3. Reopen Chrome fresh
4. Visit https://localhost

### Complete Certificate Reset

```bash
# Remove ALL old certificates
rm -rf traefik/certs/*
sudo rm -f /root/.local/share/mkcert/rootCA.pem

# Generate everything as your current user
mkcert -uninstall
rm -rf ~/.local/share/mkcert
mkcert -install

# Generate new certificates
cd traefik/certs
mkcert -cert-file localhost.pem -key-file localhost-key.pem localhost 127.0.0.1 ::1

# Verify issuer matches
openssl x509 -in localhost.pem -noout -issuer
# Should now show: CN = mkcert username@hostname

# Install in system
sudo cp ~/.local/share/mkcert/rootCA.pem /usr/local/share/ca-certificates/mkcert-rootCA.crt
sudo update-ca-certificates

# For Chrome/Chromium
certutil -d sql:$HOME/.pki/nssdb -A -t "C,," -n "mkcert" -i ~/.local/share/mkcert/rootCA.pem

# Verify it was added
certutil -d sql:$HOME/.pki/nssdb -L | grep mkcert

# If you get an error about directory not existing:
mkdir -p $HOME/.pki/nssdb
certutil -d sql:$HOME/.pki/nssdb -N --empty-password

# Then add the CA
certutil -d sql:$HOME/.pki/nssdb -A -t "C,," -n "mkcert-root" -i ~/.local/share/mkcert/rootCA.pem

# Restart
docker-compose restart traefik
```
