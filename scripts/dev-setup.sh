#!/bin/bash

# PATH Development Setup Script
# This script helps set up the local development environment

set -e

echo "🌿 Setting up PATH development environment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p local/path
mkdir -p local/observability/grafana/dashboards
mkdir -p local/observability/grafana/datasources

# Check if config file exists
if [ ! -f "local/path/.config.yaml" ]; then
    echo "❌ Configuration file not found at local/path/.config.yaml"
    echo "Please ensure the configuration file exists before running this script."
    exit 1
fi

# Build and start services
echo "🐳 Building and starting PATH services..."
docker-compose up --build -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Check service health
echo "🔍 Checking service health..."

# Check PATH service
if curl -f http://localhost:8081/health > /dev/null 2>&1; then
    echo "✅ PATH service is healthy"
else
    echo "❌ PATH service is not responding"
fi

# Check Prometheus
if curl -f http://localhost:9091/-/healthy > /dev/null 2>&1; then
    echo "✅ Prometheus is healthy"
else
    echo "❌ Prometheus is not responding"
fi

# Check Grafana
if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
    echo "✅ Grafana is healthy"
else
    echo "❌ Grafana is not responding"
fi

echo ""
echo "🎉 PATH development environment is ready!"
echo ""
echo "📊 Services available at:"
echo "  - PATH Gateway: http://localhost:8081"
echo "  - PATH Metrics: http://localhost:9090"
echo "  - Prometheus:   http://localhost:9091"
echo "  - Grafana:      http://localhost:3000 (admin/admin)"
echo "  - Loki:         http://localhost:3100"
echo ""
echo "🔧 Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Stop services: docker-compose down"
echo "  - Restart services: docker-compose restart"
echo "  - Rebuild: docker-compose up --build -d" 