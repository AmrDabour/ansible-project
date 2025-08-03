#!/bin/bash
# 3-Server Deployment Script for Note-Taking App
# Deploys from Controller (EC2 #1) to Web Server (EC2 #2)
# Database Server (EC2 #3) not used with SQLite

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo
echo "🏗️  3-Server Note-Taking App Deployment"
echo "======================================="
echo "📍 Controller: $(hostname) (Current server)"
echo "🌐 Web Server: Check inventory/hosts"
echo "🗄️ Database: SQLite on Web Server"
echo

# Check if running on controller
if [ ! -f "site.yml" ]; then
    print_error "Please run this script from the controller server in the control_server_files/ directory"
    exit 1
fi

# Step 1: Verify connectivity
print_header "Step 1: Testing connectivity to web server..."
if ansible all -i inventory/hosts -m ping; then
    print_status "✅ Web server is reachable from controller"
else
    print_error "❌ Cannot reach web server"
    echo
    echo "Troubleshooting checklist:"
    echo "1. Update inventory/hosts with your web server IP"
    echo "2. Ensure SSH key path is correct"
    echo "3. Test manual SSH: ssh -i your-key.pem ec2-user@WEB_SERVER_IP"
    echo "4. Check security groups allow SSH (port 22) from controller"
    exit 1
fi

# Step 2: Deploy application
print_header "Step 2: Deploying Note-Taking App to web server..."
ansible-playbook -i inventory/hosts site.yml -v

if [ $? -eq 0 ]; then
    echo
    print_header "🎉 Deployment Successful!"
    echo
    print_status "✅ Application deployed on web server"
    print_status "✅ SQLite database created on web server"
    print_status "✅ Backup system configured"
    echo
    echo "🌐 Access your application:"
    WEB_SERVER_IP=$(ansible-inventory -i inventory/hosts --list | grep -o '"[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*"' | tr -d '"' | head -1)
    echo "   http://$WEB_SERVER_IP"
    echo
    echo "🔧 Management commands (run from controller):"
    echo "   ./deploy_noteapp.sh status    # Check app status"
    echo "   ./deploy_noteapp.sh ping      # Test connectivity"
    echo
    echo "🗄️ Database location on web server:"
    echo "   /opt/noteapp/database/notes.db"
    echo
else
    print_error "❌ Deployment failed! Check the output above for errors."
    exit 1
fi 