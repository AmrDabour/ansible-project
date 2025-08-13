#!/bin/bash

# Simple Backup Script
echo "Creating backup..."

# Create backups directory
mkdir -p ./backups

# Get database file from .env or use default
DB_FILE=$(grep "^DB_PATH=" .env 2>/dev/null | cut -d'=' -f2 || echo "notes.db")
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Backup SQLite database
if [ -f "$DB_FILE" ]; then
    cp "$DB_FILE" "./backups/${DB_FILE}_${TIMESTAMP}"
    echo "✅ Backup created: ./backups/${DB_FILE}_${TIMESTAMP}"
else
    echo "❌ Database file not found: $DB_FILE"
fi 