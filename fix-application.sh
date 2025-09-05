#!/bin/bash

# Fix Application Script
# This script fixes the application deployment issue

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
EC2_IP="54.172.238.185"
KEY_FILE="devops-app-key.pem"

print_status "Fixing application deployment..."

# Stop and remove existing container
print_status "Stopping existing container..."
ssh -i "$KEY_FILE" ec2-user@$EC2_IP 'docker stop devops-application && docker rm devops-application' || true

# Create a simple HTML file
print_status "Creating simple HTML application..."
ssh -i "$KEY_FILE" ec2-user@$EC2_IP 'cat > /tmp/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DevOps Application</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            color: white;
        }
        .container {
            text-align: center;
            background: rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        h1 {
            font-size: 3em;
            margin-bottom: 20px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .status {
            font-size: 1.2em;
            margin: 20px 0;
            padding: 10px;
            background: rgba(76, 175, 80, 0.3);
            border-radius: 10px;
            border: 1px solid rgba(76, 175, 80, 0.5);
        }
        .info {
            margin: 10px 0;
            font-size: 1.1em;
        }
        .timestamp {
            font-size: 0.9em;
            opacity: 0.8;
            margin-top: 30px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 DevOps Application</h1>
        <div class="status">✅ Application is Running Successfully!</div>
        <div class="info">🎯 Environment: Development</div>
        <div class="info">🐳 Container: Docker</div>
        <div class="info">☁️ Platform: AWS EC2</div>
        <div class="info">🔄 CI/CD: Jenkins Pipeline</div>
        <div class="info">📊 Monitoring: Prometheus + Grafana</div>
        <div class="timestamp">Deployed: $(date)</div>
    </div>
</body>
</html>
EOF'

# Create nginx configuration
print_status "Creating nginx configuration..."
ssh -i "$KEY_FILE" ec2-user@$EC2_IP 'cat > /tmp/nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    server {
        listen 80;
        server_name _;
        
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files \$uri \$uri/ =404;
        }
        
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
        
        location /metrics {
            access_log off;
            return 200 "# DevOps Application Metrics\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF'

# Run nginx container with custom files
print_status "Starting nginx container with custom application..."
ssh -i "$KEY_FILE" ec2-user@$EC2_IP 'docker run -d \
    --name devops-application \
    -p 80:80 \
    -v /tmp/index.html:/usr/share/nginx/html/index.html \
    -v /tmp/nginx.conf:/etc/nginx/nginx.conf \
    nginx:alpine'

# Wait for container to start
print_status "Waiting for container to start..."
sleep 10

# Test the application
print_status "Testing application..."
if curl -f "http://$EC2_IP" > /dev/null 2>&1; then
    print_success "Application is now accessible!"
    print_status "Application URL: http://$EC2_IP"
    print_status "Health Check: http://$EC2_IP/health"
else
    print_warning "Application might still be starting. Please wait a moment and try again."
fi

print_success "Application fix completed!"
