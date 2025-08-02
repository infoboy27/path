# PATH Deployment Guide

This guide provides comprehensive instructions for setting up and deploying the PATH (Path API & Toolkit Harness) service both locally for development and on Ubuntu servers for production.

## 🌿 Overview

PATH is an open-source framework for enabling access to a decentralized supply network. This deployment setup includes:

- **PATH Gateway Service**: The main API gateway
- **Prometheus**: Metrics collection and monitoring
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation
- **Nginx**: Reverse proxy (production only)

## 📋 Prerequisites

### For Local Development (macOS)
- Docker Desktop
- Docker Compose
- Git

### For Production (Ubuntu Server)
- Ubuntu 20.04+ LTS
- Root or sudo access
- Domain name (optional, for SSL)

## 🚀 Local Development Setup

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/infoboy27/path.git
cd path

# Make scripts executable
chmod +x scripts/*.sh
```

### 2. Configure PATH

Edit the configuration file `local/path/.config.yaml`:

```yaml
# Update these values for your environment
shannon_config:
  gateway_config:
    gateway_address: "your-gateway-address"
    gateway_private_key_hex: "your-private-key"
    owned_apps_private_keys_hex:
      - "your-app-private-key"
```

### 3. Start Development Environment

```bash
# Run the development setup script
./scripts/dev-setup.sh

# Or manually start services
docker-compose up --build -d
```

### 4. Access Services

Once running, you can access:

- **PATH Gateway**: http://localhost:8080
- **PATH Metrics**: http://localhost:9090
- **Prometheus**: http://localhost:9091
- **Grafana**: http://localhost:3000 (admin/admin)
- **Loki**: http://localhost:3100

### 5. Testing

```bash
# Health check
curl http://localhost:8080/health

# View logs
docker-compose logs -f path

# Stop services
docker-compose down
```

## 🏭 Production Deployment

### 1. Server Preparation

```bash
# SSH into your Ubuntu server
ssh user@your-server

# Run the production deployment script
sudo ./scripts/deploy-prod.sh
```

### 2. Configuration

After deployment, update the production configuration:

```bash
# Edit the production config
sudo nano /opt/path/local/path/.config.yaml

# Update with your production values:
# - Real gateway address and private keys
# - Production endpoints
# - Proper logging levels
```

### 3. SSL Certificate (Optional)

For production with a domain name:

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# The certificate will be automatically configured
```

### 4. Service Management

```bash
# Check service status
sudo systemctl status path.service

# View logs
sudo journalctl -u path.service -f

# Monitor services
sudo /opt/path/monitor.sh

# Create backup
sudo /opt/path/backup.sh

# Restart service
sudo systemctl restart path.service
```

## 📊 Monitoring and Observability

### Grafana Dashboards

Access Grafana at `http://your-domain.com/grafana/` (default: admin/admin)

Key dashboards to create:
- PATH Gateway Metrics
- Request Latency
- Error Rates
- Resource Usage

### Prometheus Metrics

Key metrics to monitor:
- `path_requests_total`
- `path_request_duration_seconds`
- `path_errors_total`
- `path_active_connections`

### Logs

Logs are collected by Loki and can be viewed in Grafana:
- Application logs: `/var/log/path/`
- Container logs: Available in Grafana

## 🔧 Configuration Reference

### PATH Configuration Schema

The main configuration file follows this schema:

```yaml
shannon_config:
  full_node_config:
    rpc_url: "https://shannon-grove-rpc.mainnet.poktroll.com"
    grpc_config:
      host_port: "shannon-grove-grpc.mainnet.poktroll.com:443"
    lazy_mode: true
    cache_config:
      session_ttl: "30s"

  gateway_config:
    gateway_mode: "centralized"
    gateway_address: "pokt1..."
    gateway_private_key_hex: "your-private-key"
    owned_apps_private_keys_hex:
      - "app-private-key"

logger_config:
  level: "info"

router_config:
  port: 8080
  max_request_header_bytes: 1048576
  read_timeout: "30s"
  write_timeout: "30s"
  idle_timeout: "60s"

hydrator_config:
  run_interval_ms: "10000ms"
  max_concurrent_endpoint_check_workers: 100
  qos_disabled_service_ids: []

data_reporter_config:
  target_url: "http://localhost:8080/metrics"
  post_timeout_ms: 10000
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CONFIG_PATH` | Path to configuration file | `/app/.config.yaml` |
| `GRAFANA_ADMIN_PASSWORD` | Grafana admin password | `admin` |
| `NODE_ENV` | Environment mode | `production` |

## 🛠️ Troubleshooting

### Common Issues

1. **Service won't start**
   ```bash
   # Check logs
   docker-compose logs path
   
   # Verify configuration
   docker-compose exec path ./path -config /app/.config.yaml --validate
   ```

2. **High memory usage**
   ```bash
   # Check resource usage
   docker stats
   
   # Adjust limits in docker-compose.yml
   ```

3. **SSL certificate issues**
   ```bash
   # Check certificate validity
   openssl x509 -in /opt/path/local/nginx/ssl/cert.pem -text -noout
   
   # Regenerate if needed
   sudo /opt/path/scripts/generate-ssl.sh
   ```

### Health Checks

```bash
# PATH API health
curl -f http://localhost/health

# Prometheus health
curl -f http://localhost:9091/-/healthy

# Grafana health
curl -f http://localhost:3000/api/health
```

## 🔒 Security Considerations

### Production Security Checklist

- [ ] Use real SSL certificates (not self-signed)
- [ ] Update default passwords
- [ ] Configure firewall rules
- [ ] Set up proper monitoring and alerting
- [ ] Regular security updates
- [ ] Backup strategy in place
- [ ] Access control configured

### Network Security

```bash
# Configure UFW firewall
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

## 📈 Performance Tuning

### Resource Limits

Adjust in `docker-compose.prod.yml`:

```yaml
deploy:
  resources:
    limits:
      memory: 2G
      cpus: '1.0'
    reservations:
      memory: 512M
      cpus: '0.5'
```

### Nginx Optimization

Key settings in `local/nginx/nginx.conf`:
- Gzip compression enabled
- Rate limiting configured
- SSL optimization
- Security headers

## 🔄 Backup and Recovery

### Automated Backups

```bash
# Create backup
sudo /opt/path/backup.sh

# Restore from backup
sudo tar -xzf /opt/path/backups/config_YYYYMMDD_HHMMSS.tar.gz -C /opt/path/
```

### Backup Schedule

Add to crontab:
```bash
# Daily backup at 2 AM
0 2 * * * /opt/path/backup.sh
```

## 📞 Support

For issues and questions:
- GitHub Issues: [Create an issue](https://github.com/infoboy27/path/issues)
- Documentation: [path.grove.city](https://path.grove.city)
- Discord: [Grove's Discord](https://discord.gg/build-with-grove)

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details. 