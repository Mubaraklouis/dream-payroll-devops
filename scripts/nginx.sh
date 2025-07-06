#!/bin/bash

set -e

TARGET_URL="http://ec2-13-222-213-189.compute-1.amazonaws.com:8000"

echo "🔧 Updating system packages..."
sudo apt update -y

echo "📦 Installing Nginx..."
sudo apt install -y nginx

echo "📁 Creating Nginx reverse proxy configuration..."

sudo tee /etc/nginx/sites-available/reverse-proxy <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass $TARGET_URL;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

echo "🔗 Linking configuration..."
sudo ln -sf /etc/nginx/sites-available/reverse-proxy /etc/nginx/sites-enabled/default

echo "🔍 Testing Nginx configuration..."
sudo nginx -t

echo "🔁 Restarting Nginx..."
sudo systemctl restart nginx
sudo systemctl enable nginx

echo "✅ Nginx reverse proxy is set up!"
echo "🌐 All requests to this EC2 instance will be forwarded to: $TARGET_URL"
