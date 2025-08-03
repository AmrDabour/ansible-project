#!/bin/bash

# Simple Note App - Restore Script
# This script restores the application from a backup including database and files

set -e  # Exit on any error

# Configuration
APP_NAME="simple_note_app"
BACKUP_DIR="./backups"
RESTORE_LOG="./restore_$(date +"%Y%m%d_%H%M%S").log"

# Database configuration (load from .env if available)
if [ -f ".env" ]; then
    source .env
fi

DB_HOST=${DB_HOST:-"localhost"}
DB_USER=${DB_USER:-"notes_user"}
DB_PASSWORD=${DB_PASSWORD:-"notes_password"}
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
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$RESTORE_LOG"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$RESTORE_LOG"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$RESTORE_LOG"
}

print_header() {
    echo -e "${BLUE}[RESTORE]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] RESTORE: $1" >> "$RESTORE_LOG"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Show usage
show_usage() {
    echo "🔄 Simple Note App Restore Script"
    echo "================================="
    echo
    echo "Usage: $0 [BACKUP_NAME] [OPTIONS]"
    echo
    echo "BACKUP_NAME: Name of backup to restore (without .tar.gz extension)"
    echo "             Or use 'list' to show available backups"
    echo "             Or use 'latest' to restore the most recent backup"
    echo
    echo "Options:"
    echo "  --db-only      Restore only the database"
    echo "  --files-only   Restore only application files"
    echo "  --force        Skip confirmation prompts"
    echo "  --help         Show this help message"
    echo
    echo "Examples:"
    echo "  $0 list                                    # List available backups"
    echo "  $0 latest                                  # Restore latest backup"
    echo "  $0 simple_note_app_backup_20241201_143022 # Restore specific backup"
    echo "  $0 latest --db-only                       # Restore only database"
    echo "  $0 latest --force                         # Skip confirmations"
    echo
}

# List available backups
list_backups() {
    print_header "Available backups:"
    echo
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_warning "No backup directory found at: $BACKUP_DIR"
        return 1
    fi
    
    cd "$BACKUP_DIR"
    backups=($(ls -t ${APP_NAME}_backup_*.tar.gz 2>/dev/null || true))
    
    if [ ${#backups[@]} -eq 0 ]; then
        print_warning "No backups found in $BACKUP_DIR"
        return 1
    fi
    
    echo "📦 Found ${#backups[@]} backup(s):"
    echo
    
    for i in "${!backups[@]}"; do
        backup_file="${backups[$i]}"
        backup_name="${backup_file%.tar.gz}"
        backup_size=$(du -h "$backup_file" | cut -f1)
        backup_date=$(stat -c %y "$backup_file" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1 || echo "Unknown")
        
        if [ $i -eq 0 ]; then
            echo "  🌟 $backup_name (Latest)"
        else
            echo "  📄 $backup_name"
        fi
        echo "     Size: $backup_size | Date: $backup_date"
        echo
    done
    
    cd - > /dev/null
}

# Find and validate backup
find_backup() {
    local backup_name="$1"
    
    if [ "$backup_name" = "latest" ]; then
        cd "$BACKUP_DIR"
        latest_backup=$(ls -t ${APP_NAME}_backup_*.tar.gz 2>/dev/null | head -1 || true)
        cd - > /dev/null
        
        if [ -z "$latest_backup" ]; then
            print_error "No backups found!"
            return 1
        fi
        
        backup_name="${latest_backup%.tar.gz}"
        print_status "Using latest backup: $backup_name"
    fi
    
    BACKUP_FILE="$backup_name"
    BACKUP_ARCHIVE="${BACKUP_DIR}/${BACKUP_FILE}.tar.gz"
    TEMP_RESTORE_DIR="/tmp/restore_${APP_NAME}_$$"
    
    if [ ! -f "$BACKUP_ARCHIVE" ]; then
        print_error "Backup file not found: $BACKUP_ARCHIVE"
        print_status "Use '$0 list' to see available backups"
        return 1
    fi
    
    print_status "Found backup: $BACKUP_ARCHIVE"
    return 0
}

# Extract backup
extract_backup() {
    print_header "Extracting backup archive..."
    
    # Create temporary restore directory
    mkdir -p "$TEMP_RESTORE_DIR"
    
    # Extract backup
    cd "$TEMP_RESTORE_DIR"
    tar -xzf "$BACKUP_ARCHIVE"
    
    if [ ! -d "$BACKUP_FILE" ]; then
        print_error "Backup extraction failed or invalid backup structure"
        cleanup_temp_files
        return 1
    fi
    
    EXTRACTED_BACKUP_DIR="$TEMP_RESTORE_DIR/$BACKUP_FILE"
    print_status "Backup extracted to: $EXTRACTED_BACKUP_DIR"
    
    # Show backup information if available
    if [ -f "$EXTRACTED_BACKUP_DIR/backup_info.txt" ]; then
        print_header "Backup Information:"
        cat "$EXTRACTED_BACKUP_DIR/backup_info.txt"
        echo
    fi
    
    cd - > /dev/null
}

# Restore database
restore_database() {
    print_header "Restoring database..."
    
    local db_backup_file="$EXTRACTED_BACKUP_DIR/database_backup.sql"
    
    if [ ! -f "$db_backup_file" ]; then
        print_error "Database backup file not found: $db_backup_file"
        return 1
    fi
    
    if ! command_exists mysql; then
        print_error "mysql command not found! Please install MySQL/MariaDB client."
        return 1
    fi
    
    # Test database connection
    if ! mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -e "SHOW DATABASES;" >/dev/null 2>&1; then
        print_error "Cannot connect to database. Please check your database configuration."
        return 1
    fi
    
    # Create backup of current database before restore
    print_status "Creating backup of current database before restore..."
    mysqldump -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" \
        --single-transaction \
        --databases "$DB_NAME" > "/tmp/pre_restore_backup_$(date +%Y%m%d_%H%M%S).sql" 2>/dev/null || true
    
    # Restore database
    print_status "Restoring database from backup..."
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" < "$db_backup_file"
    
    print_status "Database restore completed successfully ✅"
}

# Restore application files
restore_application_files() {
    print_header "Restoring application files..."
    
    local app_files_dir="$EXTRACTED_BACKUP_DIR/app_files"
    
    if [ ! -d "$app_files_dir" ]; then
        print_error "Application files directory not found: $app_files_dir"
        return 1
    fi
    
    # Create backup of current files
    if [ -f "frontend.py" ]; then
        print_status "Creating backup of current files..."
        local current_backup_dir="./current_files_backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$current_backup_dir"
        
        for file in frontend.py requirements.txt setup_database.sh quick_setup.ps1 .env; do
            if [ -f "$file" ]; then
                cp "$file" "$current_backup_dir/"
            fi
        done
        
        if [ -d ".git" ]; then
            cp -r ".git" "$current_backup_dir/"
        fi
        
        print_status "Current files backed up to: $current_backup_dir"
    fi
    
    # Restore files
    cd "$app_files_dir"
    for file in *; do
        if [ -f "$file" ] && [ "$file" != ".git" ]; then
            cp "$file" "../../../"
            print_status "Restored: $file"
        fi
    done
    
    # Restore .git directory if exists
    if [ -d ".git" ]; then
        cp -r ".git" "../../../"
        print_status "Restored: .git directory"
    fi
    
    cd - > /dev/null
    print_status "Application files restore completed successfully ✅"
}

# Cleanup temporary files
cleanup_temp_files() {
    if [ -d "$TEMP_RESTORE_DIR" ]; then
        rm -rf "$TEMP_RESTORE_DIR"
        print_status "Cleaned up temporary files"
    fi
}

# Main restore function
main() {
    echo "🔄 Simple Note App Restore Script"
    echo "================================="
    echo
    
    # Initialize log file
    echo "Restore started at $(date)" > "$RESTORE_LOG"
    
    # Parse arguments
    local backup_name=""
    local db_only=false
    local files_only=false
    local force=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                show_usage
                exit 0
                ;;
            --db-only)
                db_only=true
                shift
                ;;
            --files-only)
                files_only=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            list)
                list_backups
                exit 0
                ;;
            *)
                if [ -z "$backup_name" ]; then
                    backup_name="$1"
                else
                    print_error "Unknown option: $1"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Check if backup name provided
    if [ -z "$backup_name" ]; then
        print_error "Please specify a backup to restore"
        echo
        show_usage
        exit 1
    fi
    
    # Validate exclusive options
    if [ "$db_only" = true ] && [ "$files_only" = true ]; then
        print_error "Cannot use --db-only and --files-only together"
        exit 1
    fi
    
    # Find and validate backup
    if ! find_backup "$backup_name"; then
        exit 1
    fi
    
    # Confirmation
    if [ "$force" != true ]; then
        echo
        print_warning "This will restore your application from backup:"
        print_status "Backup: $BACKUP_FILE"
        if [ "$db_only" = true ]; then
            print_status "Restore mode: Database only"
        elif [ "$files_only" = true ]; then
            print_status "Restore mode: Files only"
        else
            print_status "Restore mode: Complete (database + files)"
        fi
        echo
        read -p "Are you sure you want to continue? (yes/no): " confirm
        
        if [ "$confirm" != "yes" ]; then
            print_status "Restore cancelled by user"
            exit 0
        fi
    fi
    
    # Extract backup
    if ! extract_backup; then
        exit 1
    fi
    
    # Restore based on options
    if [ "$files_only" != true ]; then
        if ! restore_database; then
            cleanup_temp_files
            exit 1
        fi
    fi
    
    if [ "$db_only" != true ]; then
        if ! restore_application_files; then
            cleanup_temp_files
            exit 1
        fi
    fi
    
    # Cleanup
    cleanup_temp_files
    
    echo
    print_header "Restore completed successfully! ✅"
    print_status "Restore log saved to: $RESTORE_LOG"
    
    if [ "$files_only" != true ]; then
        print_status "Database has been restored from backup"
    fi
    
    if [ "$db_only" != true ]; then
        print_status "Application files have been restored from backup"
        print_warning "You may need to restart the application"
    fi
    
    echo
}

# Trap to cleanup on exit
trap cleanup_temp_files EXIT

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 