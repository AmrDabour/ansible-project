#!/bin/bash

# Simple Note App - SQLite Setup
echo "Setting up SQLite database..."

# Create backups directory
mkdir -p ./backups

# Load DB_PATH from .env file if exists
if [ -f ".env" ]; then
    DB_FILE=$(grep "^DB_PATH=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '\r\n')
    if [ -z "$DB_FILE" ]; then
        DB_FILE="notes.db"
    fi
else
    DB_FILE="notes.db"
fi

echo "Database file: $DB_FILE"

# Remove existing database for clean setup
if [ -f "$DB_FILE" ]; then
    echo "Backing up existing database..."
    mv "$DB_FILE" "${DB_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Create SQLite database and table
sqlite3 "$DB_FILE" << 'EOF'
CREATE TABLE IF NOT EXISTS notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    author TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
EOF

if [ $? -eq 0 ]; then
    echo "✅ SQLite database setup complete!"
    echo "Database file: $DB_FILE"
    echo "Ready to use with: python3 frontend.py"
else
    echo "❌ Failed to create SQLite database!"
    exit 1
fi 