#!/bin/bash
# =============================================================
# Ziggy — Web Tier Bootstrap Script
# Run as EC2 user-data on Ubuntu 22.04
# Installs Nginx, deploys frontend, configures reverse proxy
# =============================================================

set -e
exec > /var/log/ziggy-web-setup.log 2>&1

echo "[$(date)] Starting Ziggy web tier setup..."

# --- System update ---
apt-get update -y
apt-get install -y nginx curl unzip

# --- Deploy frontend ---
mkdir -p /var/www/html
cp /tmp/ziggy-aws-3tier-architecture/app/frontend/index.html /var/www/html/index.html

# OR clone from your repo:
# git clone https://github.com/Putta132/ziggy-aws-3tier-architecture.git /tmp/ziggy
# cp /tmp/ziggy/app/frontend/index.html /var/www/html/index.html

# --- Configure Nginx ---
# Replace INTERNAL_ALB_DNS placeholder with the actual internal ALB DNS
INTERNAL_ALB="${INTERNAL_ALB_DNS:-localhost}"

cat > /etc/nginx/sites-available/ziggy <<EOF
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass         http://${INTERNAL_ALB}:3000;
        proxy_http_version 1.1;
        proxy_set_header   Host              \$host;
        proxy_set_header   X-Real-IP         \$remote_addr;
        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
    }

    location /health {
        proxy_pass http://${INTERNAL_ALB}:3000/health;
    }
}
EOF

ln -sf /etc/nginx/sites-available/ziggy /etc/nginx/sites-enabled/ziggy
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl enable nginx
systemctl restart nginx

echo "[$(date)] Web tier setup complete. Nginx is running."
