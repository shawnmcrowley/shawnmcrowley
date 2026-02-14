#!/bin/bash

# -----------------------------
# SSL Configuration
# -----------------------------
DOMAIN="example.com"

echo "Starting SSL certificate renewal..."

# Renew certificates and reload Nginx if renewed
certbot renew --quiet --deploy-hook "systemctl reload nginx"

echo "SSL certificate for $DOMAIN has been checked and renewed if required ✅"
