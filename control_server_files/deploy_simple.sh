#!/bin/bash
# Simple Deployment Script for Note-Taking App

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo
echo "🚀 Advanced Note-Taking App Deployment"
echo "======================================="
echo

# Check if running from correct directory
if [ ! -f "site.yml" ]; then
    echo "❌ Please run this script from control_server_files/ directory"
    exit 1
fi

# Test connectivity
echo -e "${BLUE}[DEPLOY]${NC} Testing connectivity to web server..."
if ansible all -i inventory/hosts -m ping; then
    echo -e "${GREEN}✅ Web server is reachable${NC}"
else
    echo "❌ Cannot reach web server. Check your inventory/hosts file."
    exit 1
fi

# Deploy application
echo -e "${BLUE}[DEPLOY]${NC} Deploying Simple Note-Taking App..."
ansible-playbook -i inventory/hosts site.yml

if [ $? -eq 0 ]; then
    echo
    echo -e "${GREEN}🎉 Deployment Successful!${NC}"
    echo
    WEB_SERVER_IP=$(ansible-inventory -i inventory/hosts --list | grep -o '"[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*"' | tr -d '"' | head -1)
    echo "🌐 Access your advanced app: http://$WEB_SERVER_IP"
    echo "🔧 Check service: ssh to server and run 'sudo systemctl status noteapp'"
    echo
else
    echo "❌ Deployment failed!"
    exit 1
fi 