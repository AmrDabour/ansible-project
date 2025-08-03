#!/bin/bash
# Note-Taking App Ansible Deployment Script
# DevOps Project - Deploy on Amazon Linux EC2 with SQLite

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
INVENTORY="inventory/hosts"
PLAYBOOK="site.yml"
VERBOSE=""
CHECK_MODE=""
TAGS=""

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

# Show usage
show_usage() {
    echo "📝 Note-Taking App Ansible Deployment"
    echo "======================================"
    echo
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  deploy              Full deployment (default)"
    echo "  setup               System setup only"
    echo "  database            Database setup only"
    echo "  webapp              Web application only"
    echo "  backup              Backup setup only"
    echo "  check               Dry-run deployment"
    echo "  ping                Test connectivity"
    echo "  status              Check application status"
    echo "  help                Show this help"
    echo
    echo "Options:"
    echo "  -v, --verbose       Verbose output"
    echo "  -vv                 Extra verbose output"
    echo
    echo "Examples:"
    echo "  $0 deploy           # Full deployment"
    echo "  $0 deploy -v        # Verbose deployment"
    echo "  $0 check            # Dry-run"
    echo "  $0 ping             # Test connectivity"
    echo
}

# Test connectivity
test_connectivity() {
    print_header "Testing connectivity to EC2 instance..."
    cd "$SCRIPT_DIR"
    
    if ansible all -i "$INVENTORY" -m ping; then
        print_status "✅ EC2 instance is reachable"
    else
        print_error "❌ Cannot reach EC2 instance"
        echo
        echo "Troubleshooting tips:"
        echo "1. Check your EC2 instance IP in $INVENTORY"
        echo "2. Verify SSH key path is correct"
        echo "3. Ensure EC2 security group allows SSH (port 22)"
        exit 1
    fi
}

# Check application status
check_status() {
    print_header "Checking application status..."
    cd "$SCRIPT_DIR"
    
    echo "🔍 Checking systemd services..."
    ansible noteapp_servers -i "$INVENTORY" -b -m shell -a "systemctl status httpd noteapp --no-pager" || true
    
    echo
    echo "🔍 Checking application health..."
    ansible noteapp_servers -i "$INVENTORY" -m uri -a "url=http://{{ ansible_default_ipv4.address }}/health method=GET" || true
}

# Run ansible playbook
run_playbook() {
    local cmd="ansible-playbook -i $INVENTORY $PLAYBOOK"
    
    if [ -n "$VERBOSE" ]; then
        cmd="$cmd $VERBOSE"
    fi
    
    if [ -n "$CHECK_MODE" ]; then
        cmd="$cmd --check"
    fi
    
    if [ -n "$TAGS" ]; then
        cmd="$cmd --tags $TAGS"
    fi
    
    print_header "Running: $cmd"
    cd "$SCRIPT_DIR"
    eval "$cmd"
}

# Deployment functions
deploy_full() {
    print_header "Starting full Note-Taking App deployment..."
    run_playbook
}

deploy_setup() {
    print_header "Deploying system setup..."
    TAGS="common"
    run_playbook
}

deploy_database() {
    print_header "Deploying database..."
    TAGS="database"
    run_playbook
}

deploy_webapp() {
    print_header "Deploying web application..."
    TAGS="webapp"
    run_playbook
}

deploy_backup() {
    print_header "Setting up backup strategy..."
    TAGS="backup"
    run_playbook
}

check_deployment() {
    print_header "Running deployment check..."
    CHECK_MODE="--check"
    run_playbook
}

# Main function
main() {
    echo
    echo "📝 Note-Taking App Deployment"
    echo "============================="
    echo "🎯 Target: Amazon Linux EC2"
    echo "🗄️ Database: SQLite"
    echo "🐍 Framework: Python Flask"
    echo
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            deploy) COMMAND="deploy"; shift ;;
            setup) COMMAND="setup"; shift ;;
            database) COMMAND="database"; shift ;;
            webapp) COMMAND="webapp"; shift ;;
            backup) COMMAND="backup"; shift ;;
            check) COMMAND="check"; shift ;;
            ping) COMMAND="ping"; shift ;;
            status) COMMAND="status"; shift ;;
            help|--help|-h) show_usage; exit 0 ;;
            -v|--verbose) VERBOSE="-v"; shift ;;
            -vv) VERBOSE="-vv"; shift ;;
            *) print_error "Unknown option: $1"; show_usage; exit 1 ;;
        esac
    done
    
    COMMAND=${COMMAND:-deploy}
    
    # Check files exist
    if [ ! -f "$SCRIPT_DIR/$PLAYBOOK" ]; then
        print_error "Playbook not found: $PLAYBOOK"
        exit 1
    fi
    
    if [ ! -f "$SCRIPT_DIR/$INVENTORY" ]; then
        print_error "Inventory file not found: $INVENTORY"
        exit 1
    fi
    
    # Execute command
    case $COMMAND in
        deploy) deploy_full ;;
        setup) deploy_setup ;;
        database) deploy_database ;;
        webapp) deploy_webapp ;;
        backup) deploy_backup ;;
        check) check_deployment ;;
        ping) test_connectivity ;;
        status) check_status ;;
        *) print_error "Unknown command: $COMMAND"; exit 1 ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo
        print_status "✅ Command completed successfully!"
        
        if [ "$COMMAND" = "deploy" ]; then
            echo
            print_header "🎉 Deployment Complete!"
            print_status "📱 Access your app at: http://YOUR_EC2_IP"
            print_status "🔧 SSH to server: ssh -i your-key.pem ec2-user@YOUR_EC2_IP"
            print_status "📊 Check status: $0 status"
        fi
    else
        print_error "❌ Command failed!"
        exit 1
    fi
}

main "$@" 