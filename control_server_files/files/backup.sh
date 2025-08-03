#!/bin/bash
# Simple Backup Script for SQLite Database

APP_DIR="/opt/noteapp"
BACKUP_DIR="$APP_DIR/backups"
DATABASE="$APP_DIR/notes.db"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup database
if [ -f "$DATABASE" ]; then
    cp "$DATABASE" "$BACKUP_DIR/notes_backup_$DATE.db"
    echo "✅ Database backed up to: $BACKUP_DIR/notes_backup_$DATE.db"
    
    # Keep only last 7 backups
    cd $BACKUP_DIR
    ls -t notes_backup_*.db | tail -n +8 | xargs -r rm
    echo "🧹 Old backups cleaned up (keeping last 7)"
else
    echo "❌ Database not found at $DATABASE"
fi 