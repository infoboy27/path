#!/bin/bash

# PATH Production Deployment Script for Ubuntu Server
# This script sets up PATH for production deployment

set -e

echo "🚀 Setting up PATH for production deployment..."

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

# Update system packages
echo "📦 Updating system packages..."
apt-get update
apt-get upgrade -y

# Install required packages
echo "📦 Installing required packages..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    nginx \
    certbot \
    python3-certbot-nginx

# Install Docker
echo "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
fi

# Install Docker Compose
echo "🐳 Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Create PATH user
echo "👤 Creating PATH user..."
if ! id "path" &>/dev/null; then
    useradd -r -s /bin/bash -d /opt/path path
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p /opt/path/{config,logs,ssl}
mkdir -p /opt/path/local/{path,observability,nginx}
mkdir -p /opt/path/local/observability/{grafana/{dashboards,datasources},prometheus}

# Copy configuration files
echo "📋 Copying configuration files..."
cp -r config/* /opt/path/config/
cp -r local/* /opt/path/local/
cp docker-compose.prod.yml /opt/path/docker-compose.yml
cp Dockerfile /opt/path/

# Set proper permissions
echo "🔐 Setting proper permissions..."
chown -R path:path /opt/path
chmod -R 755 /opt/path
chmod 600 /opt/path/local/path/.config.yaml

# Generate self-signed SSL certificate for development
echo "🔒 Generating SSL certificate..."
if [ ! -f /opt/path/local/nginx/ssl/cert.pem ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /opt/path/local/nginx/ssl/key.pem \
        -out /opt/path/local/nginx/ssl/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
fi

# Create systemd service for PATH
echo "⚙️ Creating systemd service..."
cat > /etc/systemd/system/path.service << EOF
[Unit]
Description=PATH Gateway Service
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/path
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
echo "🚀 Enabling and starting PATH service..."
systemctl daemon-reload
systemctl enable path.service
systemctl start path.service

# Configure firewall
echo "🔥 Configuring firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Create monitoring script
echo "📊 Creating monitoring script..."
cat > /opt/path/monitor.sh << 'EOF'
#!/bin/bash

echo "=== PATH Service Status ==="
systemctl status path.service --no-pager

echo -e "\n=== Docker Containers ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n=== Service Health Checks ==="
curl -f http://localhost/health > /dev/null 2>&1 && echo "✅ PATH API: Healthy" || echo "❌ PATH API: Unhealthy"
curl -f http://localhost:9091/-/healthy > /dev/null 2>&1 && echo "✅ Prometheus: Healthy" || echo "❌ Prometheus: Unhealthy"
curl -f http://localhost:3000/api/health > /dev/null 2>&1 && echo "✅ Grafana: Healthy" || echo "❌ Grafana: Unhealthy"

echo -e "\n=== Resource Usage ==="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
EOF

chmod +x /opt/path/monitor.sh

# Create backup script
echo "💾 Creating backup script..."
cat > /opt/path/backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/opt/path/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "Creating backup: $DATE"

# Backup configuration
tar -czf $BACKUP_DIR/config_$DATE.tar.gz -C /opt/path config local

# Backup data volumes
docker run --rm -v path_prometheus_data:/data -v $BACKUP_DIR:/backup alpine tar -czf /backup/prometheus_$DATE.tar.gz -C /data .
docker run --rm -v path_grafana_data:/data -v $BACKUP_DIR:/backup alpine tar -czf /backup/grafana_$DATE.tar.gz -C /data .
docker run --rm -v path_loki_data:/data -v $BACKUP_DIR:/backup alpine tar -czf /backup/loki_$DATE.tar.gz -C /data .

echo "Backup completed: $BACKUP_DIR"
ls -la $BACKUP_DIR/*$DATE*
EOF

chmod +x /opt/path/backup.sh

# Create log rotation configuration
echo "📝 Configuring log rotation..."
cat > /etc/logrotate.d/path << EOF
/opt/path/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 path path
    postrotate
        systemctl reload path.service
    endscript
}
EOF

echo ""
echo "🎉 PATH production deployment completed!"
echo ""
echo "📊 Services available at:"
echo "  - PATH API: https://your-domain.com/api/"
echo "  - Grafana: https://your-domain.com/grafana/"
echo "  - Health: https://your-domain.com/health"
echo ""
echo "🔧 Useful commands:"
echo "  - Check status: systemctl status path.service"
echo "  - View logs: journalctl -u path.service -f"
echo "  - Monitor: /opt/path/monitor.sh"
echo "  - Backup: /opt/path/backup.sh"
echo "  - Restart: systemctl restart path.service"
echo ""
echo "⚠️  IMPORTANT:"
echo "  - Update the configuration file at /opt/path/local/path/.config.yaml"
echo "  - Replace SSL certificates with real ones for production"
echo "  - Set up proper monitoring and alerting"
echo "  - Configure regular backups" 