#!/bin/bash

# PATH Setup Test Script
# This script tests the PATH deployment to ensure everything is working correctly

set -e

echo "🧪 Testing PATH setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        return 1
    fi
}

# Test Docker and Docker Compose
echo "🐳 Testing Docker environment..."
if command -v docker &> /dev/null; then
    print_status 0 "Docker is installed"
else
    print_status 1 "Docker is not installed"
    exit 1
fi

if command -v docker-compose &> /dev/null; then
    print_status 0 "Docker Compose is installed"
else
    print_status 1 "Docker Compose is not installed"
    exit 1
fi

# Test if services are running
echo "🔍 Testing service availability..."

# Test PATH API
if curl -f http://localhost:8081/health > /dev/null 2>&1; then
    print_status 0 "PATH API is responding"
else
    print_status 1 "PATH API is not responding"
fi

# Test Prometheus
if curl -f http://localhost:9091/-/healthy > /dev/null 2>&1; then
    print_status 0 "Prometheus is responding"
else
    print_status 1 "Prometheus is not responding"
fi

# Test Grafana
if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
    print_status 0 "Grafana is responding"
else
    print_status 1 "Grafana is not responding"
fi

# Test Loki
if curl -f http://localhost:3100/ready > /dev/null 2>&1; then
    print_status 0 "Loki is responding"
else
    print_status 1 "Loki is not responding"
fi

# Test configuration file
echo "📋 Testing configuration..."
if [ -f "local/path/.config.yaml" ]; then
    print_status 0 "Configuration file exists"
else
    print_status 1 "Configuration file not found"
fi

# Test Docker containers
echo "🐳 Testing Docker containers..."
if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "path-gateway"; then
    print_status 0 "PATH container is running"
else
    print_status 1 "PATH container is not running"
fi

if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "prometheus"; then
    print_status 0 "Prometheus container is running"
else
    print_status 1 "Prometheus container is not running"
fi

if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "grafana"; then
    print_status 0 "Grafana container is running"
else
    print_status 1 "Grafana container is not running"
fi

# Test metrics endpoint
echo "📊 Testing metrics..."
if curl -f http://localhost:9090/metrics > /dev/null 2>&1; then
    print_status 0 "Metrics endpoint is accessible"
else
    print_status 1 "Metrics endpoint is not accessible"
fi

# Test basic API functionality
echo "🔌 Testing API functionality..."
if curl -f http://localhost:8081/health | grep -q "ok" 2>/dev/null; then
    print_status 0 "Health endpoint returns valid response"
else
    print_status 1 "Health endpoint returns invalid response"
fi

# Display service URLs
echo ""
echo -e "${YELLOW}📊 Service URLs:${NC}"
echo "  - PATH Gateway: http://localhost:8081"
echo "  - PATH Metrics: http://localhost:9090"
echo "  - Prometheus:   http://localhost:9091"
echo "  - Grafana:      http://localhost:3000 (admin/admin)"
echo "  - Loki:         http://localhost:3100"

# Display container status
echo ""
echo -e "${YELLOW}🐳 Container Status:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Display resource usage
echo ""
echo -e "${YELLOW}📈 Resource Usage:${NC}"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

echo ""
echo -e "${GREEN}🎉 Testing completed!${NC}"
echo ""
echo "If all tests passed, your PATH setup is working correctly."
echo "If any tests failed, check the logs with: docker-compose logs" 