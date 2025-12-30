# NGINX Forward Proxy Setup for Zscaler

**Configure NGINX as a forward proxy to handle Zscaler certificate issues with Docker containers**

[Prerequisites](#prerequisites) •
[Installation](#installation) •
[Docker Configuration](#docker-configuration) •
[Testing](#testing) •
[Troubleshooting](#troubleshooting)

---

## 📋 Overview

This guide configures a locally installed NGINX server as a forward proxy to handle Zscaler certificate inspection for Docker containers. The proxy validates certificates using Zscaler's CA, eliminating SSL/TLS errors.

## Prerequisites

- NGINX installed locally
- Zscaler root CA certificate
- Docker and Docker Compose
- Root/sudo access

---

## Installation

### 1. Get Zscaler CA Certificate

Obtain the Zscaler root CA certificate and place it in NGINX's SSL directory:

```bash
# Create SSL directory
sudo mkdir -p /etc/nginx/ssl

# Copy Zscaler CA certificate
sudo cp zscaler-ca.crt /etc/nginx/ssl/

# Set proper permissions
sudo chmod 644 /etc/nginx/ssl/zscaler-ca.crt
```

### 2. Configure NGINX as Forward Proxy

Create or modify `/etc/nginx/nginx.conf`:

```nginx
# /etc/nginx/nginx.conf

user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 768;
}

http {
    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # SSL settings with Zscaler CA
    ssl_trusted_certificate /etc/nginx/ssl/zscaler-ca.crt;
    ssl_verify_depth 5;

    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # HTTP Forward Proxy (port 3128)
    server {
        listen 3128;
        listen [::]:3128;

        # Allow proxy connections from Docker containers
        allow 127.0.0.1;
        allow 172.16.0.0/12;  # Docker default network
        allow 192.168.0.0/16; # Common internal networks
        deny all;

        location / {
            resolver 8.8.8.8;  # Google DNS
            proxy_pass http://$http_host$request_uri;
            proxy_set_header Host $http_host;
            
            # Handle Zscaler certificates
            proxy_ssl_trusted_certificate /etc/nginx/ssl/zscaler-ca.crt;
            proxy_ssl_verify on;
            proxy_ssl_verify_depth 5;
            proxy_ssl_session_reuse on;
            
            # Timeouts
            proxy_connect_timeout 30s;
            proxy_send_timeout 30s;
            proxy_read_timeout 30s;
        }
    }

    # HTTPS CONNECT Tunnel Proxy (port 3129)
    server {
        listen 3129;
        listen [::]:3129;

        allow 127.0.0.1;
        allow 172.16.0.0/12;
        allow 192.168.0.0/16;
        deny all;

        # CONNECT method support for HTTPS
        proxy_connect;
        proxy_connect_allow all;
        proxy_connect_connect_timeout 30s;
        proxy_connect_read_timeout 30s;
        proxy_connect_send_timeout 30s;

        # Zscaler certificate handling
        proxy_ssl_trusted_certificate /etc/nginx/ssl/zscaler-ca.crt;
        proxy_ssl_verify on;
        proxy_ssl_verify_depth 5;
    }
}
```

### 3. Start NGINX Service

```bash
# Test NGINX configuration
sudo nginx -t

# Start NGINX (if not running)
sudo systemctl start nginx

# Or reload configuration
sudo systemctl reload nginx

# Enable on boot
sudo systemctl enable nginx
```

---

## Docker Configuration

### Option 1: Per-Container Configuration

#### Ollama Docker Compose

```yaml
version: '3.8'

services:
  ollama:
    image: ollama/ollama
    environment:
      - HTTP_PROXY=http://host.docker.internal:3128
      - HTTPS_PROXY=http://host.docker.internal:3128
      - NO_PROXY=localhost,127.0.0.1
    volumes:
      - ollama_data:/root/.ollama
    extra_hosts:
      - "host.docker.internal:host-gateway"
    restart: unless-stopped

volumes:
  ollama_data:
```

#### n8n Docker Compose

```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n
    environment:
      - HTTP_PROXY=http://host.docker.internal:3128
      - HTTPS_PROXY=http://host.docker.internal:3128
      - NO_PROXY=localhost,127.0.0.1
    volumes:
      - n8n_data:/home/node/.n8n
    extra_hosts:
      - "host.docker.internal:host-gateway"
    restart: unless-stopped

volumes:
  n8n_data:
```

### Option 2: Docker Daemon-Wide Configuration

Configure ALL Docker containers to use the proxy by default.

Create `/etc/systemd/system/docker.service.d/http-proxy.conf`:

```ini
[Service]
Environment="HTTP_PROXY=http://localhost:3128"
Environment="HTTPS_PROXY=http://localhost:3128"
Environment="NO_PROXY=localhost,127.0.0.1"
```

Restart Docker daemon:

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

---

## Testing

### Test HTTP Proxy

```bash
# Test HTTP proxy
curl -x http://localhost:3128 http://httpbin.org/ip

# Test HTTPS through proxy (should work with Zscaler)
curl -x http://localhost:3128 https://httpbin.org/ip
```

### Test from Docker Container

```bash
# Run test container with proxy
docker run --rm \
  -e HTTP_PROXY=http://host.docker.internal:3128 \
  -e HTTPS_PROXY=http://host.docker.internal:3128 \
  --add-host=host.docker.internal:host-gateway \
  curlimages/curl:latest \
  https://httpbin.org/ip
```

---

## Firewall Configuration

Ensure proxy ports are accessible to Docker networks:

```bash
# Allow Docker network to access proxy ports
sudo ufw allow from 172.16.0.0/12 to any port 3128,3129
```

---

## Enhanced Logging (Optional)

Add detailed logging for debugging:

```nginx
# Add to http block in nginx.conf
log_format proxy_format '$remote_addr - $remote_user [$time_local] '
                       '"$request" $status $body_bytes_sent '
                       '"$http_referer" "$http_user_agent" '
                       'proxy: "$proxy_host" "$upstream_addr"';

access_log /var/log/nginx/proxy.log proxy_format;
```

View logs:

```bash
# Watch proxy logs in real-time
sudo tail -f /var/log/nginx/proxy.log

# View error logs
sudo tail -f /var/log/nginx/error.log
```

---

## Troubleshooting

### NGINX Won't Start

```bash
# Check configuration syntax
sudo nginx -t

# Check if ports are already in use
sudo netstat -tlnp | grep -E '3128|3129'

# View detailed error logs
sudo journalctl -u nginx -n 50
```

### Docker Containers Can't Reach Proxy

```bash
# Verify host.docker.internal resolves
docker run --rm --add-host=host.docker.internal:host-gateway alpine ping -c 3 host.docker.internal

# Check NGINX is listening
sudo netstat -tlnp | grep nginx

# Test from host
curl -x http://localhost:3128 http://httpbin.org/ip
```

### Certificate Errors Persist

```bash
# Verify Zscaler CA certificate exists
ls -la /etc/nginx/ssl/zscaler-ca.crt

# Check certificate format (should be PEM)
openssl x509 -in /etc/nginx/ssl/zscaler-ca.crt -text -noout

# Reload NGINX after certificate changes
sudo systemctl reload nginx
```

---

## Key Configuration Details

| Component | Value | Description |
|-----------|-------|-------------|
| **HTTP Proxy Port** | `3128` | Standard forward proxy port |
| **HTTPS Proxy Port** | `3129` | HTTPS CONNECT tunnel port |
| **Docker Host** | `host.docker.internal` | Special DNS name pointing to host |
| **Zscaler CA Path** | `/etc/nginx/ssl/zscaler-ca.crt` | Trusted certificate location |
| **Allowed Networks** | `172.16.0.0/12`, `192.168.0.0/16` | Docker and internal networks |

---

## Summary

This setup allows Docker containers to route outbound HTTPS traffic through your local NGINX proxy, which properly handles Zscaler's certificate inspection without SSL/TLS errors.

**Benefits:**
- ✅ Eliminates Zscaler certificate errors
- ✅ Works with all Docker containers
- ✅ No container image modifications needed
- ✅ Centralized proxy management
- ✅ Enhanced logging and monitoring

---

<div align="center">
Made with ❤️ for Docker + Zscaler environments
</div>
