#!/bin/bash

# Simple Restore Script
echo "Available backups:"
ls -la ./backups/ 2>/dev/null || echo "No backups found"

echo ""
echo "Enter backup filename to restore:"
read BACKUP_FILE

# Get current database file from .env or use default
DB_FILE=$(grep "^DB_PATH=" .env 2>/dev/null | cut -d'=' -f2 || echo "notes.db")

# Restore backup
if [ -f "./backups/$BACKUP_FILE" ]; then
    cp "./backups/$BACKUP_FILE" "$DB_FILE"
    echo "✅ Database restored from: $BACKUP_FILE"
else
    echo "❌ Backup file not found: $BACKUP_FILE"
fi 