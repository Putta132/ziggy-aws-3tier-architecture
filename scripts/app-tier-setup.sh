#!/bin/bash
# =============================================================
# Ziggy — App Tier Bootstrap Script
# Run as EC2 user-data on Ubuntu 22.04 (private subnet)
# Installs Node.js, clones repo, starts Express API with PM2
# =============================================================

set -e
exec > /var/log/ziggy-app-setup.log 2>&1

echo "[$(date)] Starting Ziggy app tier setup..."

# --- System update ---
apt-get update -y
apt-get install -y curl git

# --- Install Node.js 20 LTS ---
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# --- Install PM2 (process manager — keeps Node alive, restarts on crash) ---
npm install -g pm2

# --- Clone application code ---
git clone https://github.com/Putta132/ziggy-aws-3tier-architecture.git /opt/ziggy
cd /opt/ziggy/app/backend

# --- Install dependencies ---
npm install --production

# --- Set environment variables ---
# These are passed in via EC2 user-data environment or AWS Parameter Store
cat > /opt/ziggy/app/backend/.env <<EOF
PORT=3000
DB_HOST=${DB_HOST}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=ziggydb
EOF

# --- Run DB schema (first-time setup only) ---
# mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} < /opt/ziggy/app/backend/schema.sql

# --- Start app with PM2 ---
cd /opt/ziggy/app/backend
pm2 start server.js --name "ziggy-api"
pm2 startup systemd -u ubuntu --hp /home/ubuntu
pm2 save

echo "[$(date)] App tier setup complete. Node.js API running on port 3000."
