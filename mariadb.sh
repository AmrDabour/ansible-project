#!/bin/bash

# Simple Note App - MariaDB Setup
echo "Setting up MariaDB database..."

# Load configuration from .env file if exists
if [ -f ".env" ]; then
    DB_HOST=$(grep "^DB_HOST=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '\r\n')
    DB_USER=$(grep "^DB_USER=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '\r\n')  
    DB_PASSWORD=$(grep "^DB_PASSWORD=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '\r\n')
    DB_NAME=$(grep "^DB_NAME=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '\r\n')
    DB_PORT=$(grep "^DB_PORT=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '\r\n')
else
    DB_HOST="localhost"
    DB_USER="notes_user"
    DB_PASSWORD="notes_password"
    DB_NAME="notes_db"
    DB_PORT="3306"
fi

# Set defaults if empty
DB_HOST=${DB_HOST:-"localhost"}
DB_USER=${DB_USER:-"notes_user"}
DB_PASSWORD=${DB_PASSWORD:-"notes_password"}
DB_NAME=${DB_NAME:-"notes_db"}
DB_PORT=${DB_PORT:-"3306"}

echo "Database config: ${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

# Prompt for MySQL root password
echo "Enter MariaDB root password:"
read -s ROOT_PASSWORD

# Execute MariaDB commands
mysql -u root -p"$ROOT_PASSWORD" << EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'${DB_HOST}';
USE \`${DB_NAME}\`;
CREATE TABLE IF NOT EXISTS notes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    author VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
FLUSH PRIVILEGES;
EOF

if [ $? -eq 0 ]; then
    echo "✅ MariaDB database setup complete!"
    echo "Database: ${DB_NAME}"
    echo "User: ${DB_USER}"
    echo "Password: ${DB_PASSWORD}"
else
    echo "❌ Failed to create MariaDB database!"
    exit 1
fi 