# SSL Certificate Creation and Configuration for Windows

## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Install mkcert on Windows](#install-mkcert-on-windows)
- [Generate SSL Certificates](#generate-ssl-certificates)
- [Part 1: Install Certificate on a Web Server](#part-1-install-certificate-on-a-web-server)
  - [Apache Server Configuration](#apache-server-configuration)
  - [Nginx Server Configuration](#nginx-server-configuration)
- [Part 2: Install Certificate in Windows Desktop for Browsers](#part-2-install-certificate-in-windows-desktop-for-browsers)
  - [Install in Windows Trust Store](#install-in-windows-trust-store)
  - [Chromium-Based Browser Configuration](#chromium-based-browser-configuration)
  - [Firefox Configuration](#firefox-configuration)
- [Troubleshooting](#troubleshooting)
- [References](#references)

## Introduction

This guide provides step-by-step instructions for creating SSL certificates using mkcert on Windows and applying them to:
1. A web server (Apache or Nginx)
2. A Windows desktop for browser trust

mkcert creates locally trusted development certificates, allowing you to use HTTPS locally without browser security warnings.

## Prerequisites

- Windows 10 or 11 (Pro recommended for system-wide certificate installation)
- PowerShell 5.1 or later
- Administrative privileges (required for system-wide certificate installation and server configuration)
- Web server software (Apache or Nginx) if configuring a web server

## Install mkcert on Windows

### Option 1: Using Chocolatey (Recommended)

1. Install [Chocolatey](https://chocolatey.org/install) if not already installed:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
   ```

2. Install mkcert:
   ```powershell
   choco install mkcert -y
   ```

### Option 2: Manual Installation

1. Download the latest Windows binary from [mkcert releases](https://github.com/FiloSottile/mkcert/releases)
2. Extract the ZIP file to a permanent location (e.g., `C:\tools\mkcert`)
3. Add the location to your PATH environment variable:
   ```powershell
   [Environment]::SetEnvironmentVariable("Path", "$env:Path;C:\tools\mkcert", "User")
   ```
4. Restart PowerShell or your terminal

### Verify Installation

```powershell
mkcert --version
```

## Generate SSL Certificates

1. Create a directory for certificates:
   ```powershell
   New-Item -ItemType Directory -Path "C:\certs" -Force
   ```

2. Navigate to the certs directory:
   ```powershell
   cd "C:\certs"
   ```

3. Generate certificates for localhost (run as Administrator):
   ```powershell
   mkcert -cert-file localhost.pem -key-file localhost-key.pem localhost 127.0.0.1 ::1
   ```

4. Verify the files were created:
   ```powershell
   Get-ChildItem localhost.pem localhost-key.pem
   ```

5. Install the local CA (required for browser trust):
   ```powershell
   mkcert -install
   ```

## Part 1: Install Certificate on a Web Server

### Apache Server Configuration

#### Step 1: Configure Apache for SSL

1. Open the Apache configuration file:
   ```powershell
   notepad "C:\Apache24\conf\httpd.conf"
   ```

2. Ensure the following modules are uncommented:
   ```apache
   LoadModule ssl_module modules/mod_ssl.so
   LoadModule socache_shmcb_module modules/mod_socache_shmcb.so
   ```

3. Add or modify the following at the end of the file:
   ```apache
   Listen 443
   ```

4. Save and close the file

#### Step 2: Create SSL Configuration

1. Create a new SSL configuration file:
   ```powershell
   notepad "C:\Apache24\conf\extra\httpd-ssl.conf"
   ```

2. Add the following configuration (adjust paths as needed):
   ```apache
   <IfModule ssl_module>
   <VirtualHost *:443>
       ServerName localhost
       ServerAdmin admin@example.com
       DocumentRoot "C:/Apache24/htdocs"
       ErrorLog "logs/error.log"
       CustomLog "logs/access.log" common

       SSLEngine on
       SSLCertificateFile "C:/certs/localhost.pem"
       SSLCertificateKeyFile "C:/certs/localhost-key.pem"

       <FilesMatch "\.(cgi|shtml|phtml|php)$">
           SSLOptions +StdEnvVars
       </FilesMatch>
       <Directory "C:/Apache24/cgi-bin">
           SSLOptions +StdEnvVars
       </Directory>

       BrowserMatch "MSIE [2-5]" \
           nokeepalive ssl-unclean-shutdown \
           downgrade-1.0 force-response-1.0
       # MSIE 7 and newer should be able to use keepalive
       BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown
   </VirtualHost>
   </IfModule>
   ```

3. Save and close the file

#### Step 3: Include SSL Configuration

1. Open the main configuration file again:
   ```powershell
   notepad "C:\Apache24\conf\httpd.conf"
   ```

2. Add this line at the end of the file:
   ```apache
   Include conf/extra/httpd-ssl.conf
   ```

3. Save and close the file

#### Step 4: Start Apache with SSL

1. Open Command Prompt as Administrator
2. Navigate to Apache directory:
   ```cmd
   cd C:\Apache24\bin
   ```
3. Start Apache:
   ```cmd
   httpd.exe
   ```

4. Verify Apache is running:
   ```powershell
   netstat -ano | findstr 443
   ```

5. Test in browser: [https://localhost](https://localhost)

### Nginx Server Configuration

#### Step 1: Configure Nginx for SSL

1. Open the Nginx configuration file:
   ```powershell
   notepad "C:\nginx\conf\nginx.conf"
   ```

2. Add the following server block inside the `http` block:
   ```nginx
   server {
       listen 443 ssl;
       server_name localhost;

       ssl_certificate "C:/certs/localhost.pem";
       ssl_certificate_key "C:/certs/localhost-key.pem";

       location / {
           root C:/nginx/www;
           index index.html index.htm;
       }

       error_page 500 502 503 504 /50x.html;
       location = /50x.html {
           root C:/nginx/html;
       }
   }
   ```

3. Save and close the file

#### Step 2: Start Nginx with SSL

1. Open Command Prompt as Administrator
2. Navigate to Nginx directory:
   ```cmd
   cd C:\nginx
   ```
3. Start Nginx:
   ```cmd
   start nginx.exe
   ```

4. Verify Nginx is running:
   ```powershell
   netstat -ano | findstr 443
   ```

5. Test in browser: [https://localhost](https://localhost)

## Part 2: Install Certificate in Windows Desktop for Browsers

### Install in Windows Trust Store

#### Method 1: Using certutil (PowerShell - Administrator)

```powershell
# Find the mkcert root CA location
$caroot = mkcert -CAROOT

# Install the CA in the Trusted Root Certification Authorities store
certutil -addstore -f "ROOT" "$caroot\rootCA.pem"
```

#### Method 2: Interactive Installation (GUI)

1. Open the mkcert directory in Windows Explorer:
   ```powershell
   explorer.exe "$env:USERPROFILE\.local\share\mkcert"
   ```

2. Double-click `rootCA.pem`
3. Click "Install Certificate..."
4. Select "Local Machine" (requires admin) → Next
5. Choose "Place all certificates in the following store"
6. Click "Browse" → Select "Trusted Root Certification Authorities" → OK
7. Click Next → Finish

#### Verify Installation

```powershell
# Check if the certificate is in the Trusted Root store
certutil -store ROOT | Select-String -Pattern "mkcert"
```

### Chromium-Based Browser Configuration

Chromium-based browsers (Chrome, Edge, Brave, etc.) use the Windows Certificate Store by default. However, you may need to:

#### Clear HSTS Cache

1. Open a new tab and navigate to:
   ```
   chrome://net-internals/#hsts
   ```

2. In the "Delete domain security policies" section:
   - Enter `localhost`
   - Click "Delete"

3. Restart the browser

#### Alternative: Use Incognito Mode

Chromium-based browsers in Incognito mode don't use the HSTS cache, so certificates will work immediately.

### Firefox Configuration

Firefox has its own certificate store and requires separate configuration:

#### Method 1: Automatic Installation (Recommended)

When you run `mkcert -install`, it should automatically install the CA in Firefox. Verify with:
```powershell
mkcert -CAROOT
```

#### Method 2: Manual Installation

1. Open Firefox
2. Go to: `about:preferences#privacy`
3. Scroll down to "Certificates" → "View Certificates"
4. Go to the "Authorities" tab
5. Click "Import..."
6. Navigate to: `%USERPROFILE%\.local\share\mkcert\rootCA.pem`
7. Check "Trust this CA to identify websites" → OK
8. Restart Firefox

## Troubleshooting

### Certificate Not Trusted

1. **Verify certificate installation**:
   ```powershell
   certutil -store ROOT | Select-String -Pattern "mkcert"
   ```

2. **Reinstall the certificate** (if missing):
   ```powershell
   $caroot = mkcert -CAROOT
   certutil -addstore -f "ROOT" "$caroot\rootCA.pem"
   ```

### Browser Shows Security Warning

1. **Close all browser windows completely** (check system tray for running instances)
2. **Use Incognito mode** to test
3. **Clear HSTS cache** as shown above
4. **Restart your computer** (sometimes required for certificate changes to take effect)

### Server Not Using Certificate

1. **Verify file paths** are correct in your server configuration
2. **Check server logs** for SSL-related errors
3. **Verify certificate permissions**:
   ```powershell
   icacls "C:\certs\localhost.pem"
   icacls "C:\certs\localhost-key.pem"
   ```
4. **Restart the server** after configuration changes

### Complete Certificate Reset

```powershell
# Remove old certificates
Remove-Item -Recurse -Force "C:\certs"

# Uninstall mkcert CA
mkcert -uninstall

# Remove mkcert directory
Remove-Item -Recurse -Force "$env:USERPROFILE\.local\share\mkcert"

# Reinstall mkcert
mkcert -install

# Generate new certificates
cd "C:\certs"
mkcert -cert-file localhost.pem -key-file localhost-key.pem localhost 127.0.0.1 ::1

# Reinstall in Windows Trust Store
$caroot = mkcert -CAROOT
certutil -addstore -f "ROOT" "$caroot\rootCA.pem"
```

## References

- [mkcert GitHub Repository](https://github.com/FiloSottile/mkcert)
- [Apache SSL/TLS Configuration](https://httpd.apache.org/docs/current/ssl/)
- [Nginx SSL/TLS Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [Windows certutil Documentation](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/certutil)
