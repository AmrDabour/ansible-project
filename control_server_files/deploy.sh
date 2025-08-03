#!/bin/bash

# Simple Note App Ansible Deployment Script
# This script provides easy deployment options for the Simple Note App

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYBOOK_DIR="$SCRIPT_DIR"

# Default values
PLAYBOOK="deploy.yml"
INVENTORY="hosts"
VERBOSE=""
CHECK_MODE=""
TAGS=""
SKIP_TAGS=""

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
    echo "🚀 Simple Note App Deployment Script"
    echo "===================================="
    echo
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  deploy              Full deployment (default)"
    echo "  db-only             Deploy only database server"
    echo "  web-only            Deploy only web server"
    echo "  check               Dry-run deployment (check mode)"
    echo "  ping                Test connectivity to all servers"
    echo "  setup-db            Initialize database only"
    echo "  restart-app         Restart application service"
    echo "  status              Check application status"
    echo "  logs                Show application logs"
    echo "  help                Show this help message"
    echo
    echo "Options:"
    echo "  -v, --verbose       Verbose output"
    echo "  -vv, --extra-verbose Very verbose output"
    echo "  -i INVENTORY        Use custom inventory file"
    echo "  --check             Run in check mode (dry-run)"
    echo "  --tags TAGS         Run only specified tags"
    echo "  --skip-tags TAGS    Skip specified tags"
    echo
    echo "Examples:"
    echo "  $0 deploy                    # Full deployment"
    echo "  $0 deploy -v                 # Verbose deployment"
    echo "  $0 check                     # Dry-run deployment"
    echo "  $0 db-only                   # Deploy database only"
    echo "  $0 web-only                  # Deploy web server only"
    echo "  $0 ping                      # Test connectivity"
    echo "  $0 status                    # Check app status"
    echo
}

# Test connectivity
test_connectivity() {
    print_header "Testing connectivity to all servers..."
    cd "$PLAYBOOK_DIR"
    
    if ansible all -i "$INVENTORY" -m ping; then
        print_status "✅ All servers are reachable"
    else
        print_error "❌ Some servers are not reachable"
        exit 1
    fi
}

# Run ansible playbook
run_playbook() {
    local cmd="ansible-playbook -i $INVENTORY $PLAYBOOK"
    
    # Add options
    if [ -n "$VERBOSE" ]; then
        cmd="$cmd $VERBOSE"
    fi
    
    if [ -n "$CHECK_MODE" ]; then
        cmd="$cmd --check"
    fi
    
    if [ -n "$TAGS" ]; then
        cmd="$cmd --tags $TAGS"
    fi
    
    if [ -n "$SKIP_TAGS" ]; then
        cmd="$cmd --skip-tags $SKIP_TAGS"
    fi
    
    print_header "Running: $cmd"
    cd "$PLAYBOOK_DIR"
    eval "$cmd"
}

# Database-only deployment
deploy_db_only() {
    print_header "Deploying database server only..."
    TAGS="database"
    run_playbook
}

# Web-only deployment
deploy_web_only() {
    print_header "Deploying web server only..."
    TAGS="web"
    run_playbook
}

# Full deployment
deploy_full() {
    print_header "Starting full deployment..."
    run_playbook
}

# Check deployment (dry-run)
check_deployment() {
    print_header "Running deployment check (dry-run)..."
    CHECK_MODE="--check"
    run_playbook
}

# Setup database
setup_database() {
    print_header "Initializing database..."
    cd "$PLAYBOOK_DIR"
    ansible-playbook -i "$INVENTORY" -l db setup_database.yml $VERBOSE
}

# Restart application
restart_app() {
    print_header "Restarting application service..."
    cd "$PLAYBOOK_DIR"
    ansible web -i "$INVENTORY" -b -m systemd -a "name=simple-note-app state=restarted" $VERBOSE
}

# Check application status
check_status() {
    print_header "Checking application status..."
    cd "$PLAYBOOK_DIR"
    
    echo "🔍 Checking service status..."
    ansible web -i "$INVENTORY" -b -m systemd -a "name=simple-note-app" $VERBOSE
    
    echo
    echo "🔍 Checking application health..."
    ansible web -i "$INVENTORY" -m uri -a "url=http://{{ ansible_default_ipv4.address }}:5000 method=GET" $VERBOSE
}

# Show application logs
show_logs() {
    print_header "Showing application logs..."
    cd "$PLAYBOOK_DIR"
    ansible web -i "$INVENTORY" -b -m shell -a "journalctl -u simple-note-app -n 50 --no-pager" $VERBOSE
}

# Create database setup playbook if it doesn't exist
create_db_setup() {
    if [ ! -f "$PLAYBOOK_DIR/setup_database.yml" ]; then
        print_status "Creating database setup playbook..."
        cat > "$PLAYBOOK_DIR/setup_database.yml" << 'EOF'
---
- name: Setup Database Tables
  hosts: web
  become: yes
  vars_files:
    - vars/main.yml

  tasks:
    - name: Run database setup script
      shell: |
        cd {{ app_dir }}
        source venv/bin/activate
        bash setup_database.sh
      become_user: "{{ app_user }}"
      environment:
        DB_HOST: "{{ db_host }}"
        DB_USER: "{{ db_user }}"
        DB_PASSWORD: "{{ db_password }}"
        DB_NAME: "{{ db_name }}"
EOF
    fi
}

# Main function
main() {
    # Create necessary files
    create_db_setup
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            deploy)
                COMMAND="deploy"
                shift
                ;;
            db-only)
                COMMAND="db-only"
                shift
                ;;
            web-only)
                COMMAND="web-only"
                shift
                ;;
            check)
                COMMAND="check"
                shift
                ;;
            ping)
                COMMAND="ping"
                shift
                ;;
            setup-db)
                COMMAND="setup-db"
                shift
                ;;
            restart-app)
                COMMAND="restart-app"
                shift
                ;;
            status)
                COMMAND="status"
                shift
                ;;
            logs)
                COMMAND="logs"
                shift
                ;;
            help|--help|-h)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE="-v"
                shift
                ;;
            -vv|--extra-verbose)
                VERBOSE="-vv"
                shift
                ;;
            -i)
                INVENTORY="$2"
                shift 2
                ;;
            --check)
                CHECK_MODE="--check"
                shift
                ;;
            --tags)
                TAGS="$2"
                shift 2
                ;;
            --skip-tags)
                SKIP_TAGS="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Default command
    COMMAND=${COMMAND:-deploy}
    
    # Check if required files exist
    if [ ! -f "$PLAYBOOK_DIR/$PLAYBOOK" ]; then
        print_error "Playbook not found: $PLAYBOOK"
        exit 1
    fi
    
    if [ ! -f "$PLAYBOOK_DIR/$INVENTORY" ]; then
        print_error "Inventory file not found: $INVENTORY"
        exit 1
    fi
    
    # Execute command
    case $COMMAND in
        deploy)
            deploy_full
            ;;
        db-only)
            deploy_db_only
            ;;
        web-only)
            deploy_web_only
            ;;
        check)
            check_deployment
            ;;
        ping)
            test_connectivity
            ;;
        setup-db)
            setup_database
            ;;
        restart-app)
            restart_app
            ;;
        status)
            check_status
            ;;
        logs)
            show_logs
            ;;
        *)
            print_error "Unknown command: $COMMAND"
            show_usage
            exit 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        print_status "✅ Command completed successfully!"
    else
        print_error "❌ Command failed!"
        exit 1
    fi
}

# Run main function
main "$@" 