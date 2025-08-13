#!/bin/bash

# Simple Note App - SQLite Setup for Docker
echo "Setting up SQLite database in container..."

# Create shared directory
mkdir -p /shared

# Set database file path for Docker environment
DB_FILE="/shared/notes.db"

echo "Database file: $DB_FILE"

# Remove any existing database for clean setup
if [ -f "$DB_FILE" ]; then
    echo "Removing existing database for fresh setup..."
    rm -f "$DB_FILE"
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