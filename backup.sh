#!/bin/bash

# Simple Note App - Backup Script
# This script creates a complete backup of the application including database and files

set -e  # Exit on any error

# Configuration
APP_NAME="simple_note_app"
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${APP_NAME}_backup_${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE}"

# Database configuration (load from .env if available)
if [ -f ".env" ]; then
    source .env
fi

DB_HOST=${DB_HOST:-"localhost"}
DB_USER=${DB_USER:-"notes_user"}
DB_PASSWORD=${DB_PASSWORD:-"amr"}
DB_NAME=${DB_NAME:-"simple_notes"}
DB_PORT=${DB_PORT:-3306}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "${BLUE}[BACKUP]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create backup directory
create_backup_dir() {
    print_header "Creating backup directory..."
    
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        print_status "Created backup directory: $BACKUP_DIR"
    else
        print_status "Backup directory exists: $BACKUP_DIR"
    fi
    
    # Create timestamped backup folder
    mkdir -p "$BACKUP_PATH"
    print_status "Created backup folder: $BACKUP_PATH"
}

# Backup database
backup_database() {
    print_header "Backing up database..."
    
    if ! command_exists mysqldump; then
        print_error "mysqldump not found! Please install MySQL/MariaDB client."
        return 1
    fi
    
    # Test database connection
    if ! mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -e "USE $DB_NAME;" 2>/dev/null; then
        print_error "Cannot connect to database. Please check your database configuration."
        return 1
    fi
    
    # Create database backup
    mysqldump -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" \
        --single-transaction \
        --routines \
        --triggers \
        --add-drop-database \
        --databases "$DB_NAME" > "$BACKUP_PATH/database_backup.sql"
    
    print_status "Database backup completed: $BACKUP_PATH/database_backup.sql"
}

# Backup application files
backup_application_files() {
    print_header "Backing up application files..."
    
    # Create app files directory in backup
    mkdir -p "$BACKUP_PATH/app_files"
    
    # Files to backup
    files_to_backup=(
        "frontend.py"
        "requirements.txt"
        "setup_database.sh"
        "quick_setup.ps1"
        ".env"
        "Ansible.pem"
    )
    
    for file in "${files_to_backup[@]}"; do
        if [ -f "$file" ]; then
            cp "$file" "$BACKUP_PATH/app_files/"
            print_status "Backed up: $file"
        else
            print_warning "File not found, skipping: $file"
        fi
    done
    
    # Backup .git directory if exists
    if [ -d ".git" ]; then
        cp -r ".git" "$BACKUP_PATH/app_files/"
        print_status "Backed up: .git directory"
    fi
}

# Create backup metadata
create_backup_metadata() {
    print_header "Creating backup metadata..."
    
    cat > "$BACKUP_PATH/backup_info.txt" << EOF
Simple Note App Backup Information
==================================
Backup Date: $(date)
Backup Version: 1.0
Application: $APP_NAME

Database Information:
- Host: $DB_HOST
- Port: $DB_PORT
- Database: $DB_NAME
- User: $DB_USER

Files Included:
$(find "$BACKUP_PATH/app_files" -type f -exec basename {} \; 2>/dev/null || echo "No app files")

Backup Structure:
- database_backup.sql: Complete database dump
- app_files/: Application source files and configuration
- backup_info.txt: This metadata file

Restore Instructions:
Run: ./restore.sh $BACKUP_FILE
EOF

    print_status "Backup metadata created: $BACKUP_PATH/backup_info.txt"
}

# Create compressed archive
create_archive() {
    print_header "Creating compressed backup archive..."
    
    if command_exists tar; then
        cd "$BACKUP_DIR"
        tar -czf "${BACKUP_FILE}.tar.gz" "$BACKUP_FILE"
        
        # Remove uncompressed backup folder
        rm -rf "$BACKUP_FILE"
        
        print_status "Compressed backup created: ${BACKUP_DIR}/${BACKUP_FILE}.tar.gz"
        
        # Show backup size
        backup_size=$(du -h "${BACKUP_FILE}.tar.gz" | cut -f1)
        print_status "Backup size: $backup_size"
        
        cd - > /dev/null
    else
        print_warning "tar not available, keeping uncompressed backup"
    fi
}

# Cleanup old backups (keep last 5)
cleanup_old_backups() {
    print_header "Cleaning up old backups..."
    
    cd "$BACKUP_DIR"
    
    # Count backup files
    backup_count=$(ls -1 ${APP_NAME}_backup_*.tar.gz 2>/dev/null | wc -l || echo 0)
    
    if [ "$backup_count" -gt 5 ]; then
        # Remove oldest backups, keep latest 5
        ls -t ${APP_NAME}_backup_*.tar.gz | tail -n +6 | xargs rm -f
        removed_count=$((backup_count - 5))
        print_status "Removed $removed_count old backup(s), kept latest 5"
    else
        print_status "No cleanup needed, backup count: $backup_count"
    fi
    
    cd - > /dev/null
}

# Main backup function
main() {
    echo "🗂️  Simple Note App Backup Script"
    echo "=================================="
    echo
    
    print_status "Starting backup process..."
    print_status "Backup timestamp: $TIMESTAMP"
    
    # Execute backup steps
    create_backup_dir
    backup_database
    backup_application_files
    create_backup_metadata
    create_archive
    cleanup_old_backups
    
    echo
    print_header "Backup completed successfully! ✅"
    print_status "Backup location: ${BACKUP_DIR}/${BACKUP_FILE}.tar.gz"
    print_status "To restore this backup, run: ./restore.sh ${BACKUP_FILE}"
    echo
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 