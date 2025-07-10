#!/bin/bash

# Exit jika ada error
set -e

echo "[+] Downloading Caddy..."
curl -fsSL https://caddyserver.com/api/download\?os\=linux\&arch\=amd64 | tar -xzf - caddy

echo "[+] Moving binary to /usr/bin..."
sudo mv caddy /usr/bin/caddy
sudo chmod +x /usr/bin/caddy

echo "[+] Verifying Caddy version..."
caddy version

echo "[+] Creating Caddy log directory..."
mkdir -p /var/log/caddy

echo "[+] Starting Caddy in background with log..."

cp Caddyfile /etc/caddy/Caddyfile
sudo chown root:root /etc/caddy/Caddyfile
sudo chmod 644 /etc/caddy/Caddyfile
# Start Caddy dengan config lokal dan redirect log
nohup caddy run --config /etc/caddy/Caddyfile --adapter caddyfile > /var/log/caddy/access.log 2>&1 &

echo "[✓] Caddy started. Logs: /var/log/caddy/access.log"
