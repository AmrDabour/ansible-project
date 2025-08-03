#!/bin/bash

# Simple Note App - MariaDB Database Setup Script
# This script sets up MariaDB database and creates the notes table

set -e  # Exit on any error

echo "🚀 Starting MariaDB setup for Simple Note App..."

# Configuration variables
DB_NAME="simple_notes"
DB_USER="notes_user"
DB_PASSWORD="notes_password"
DB_ROOT_PASSWORD=""

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
    echo -e "${BLUE}[SETUP]${NC} $1"
}

# Check if MariaDB is installed
check_mariadb() {
    print_header "Checking MariaDB installation..."
    
    if command -v mysql >/dev/null 2>&1; then
        print_status "MariaDB client found ✓"
    else
        print_error "MariaDB client not found!"
        echo "Please install MariaDB first:"
        echo "  Ubuntu/Debian: sudo apt update && sudo apt install mariadb-server mariadb-client"
        echo "  CentOS/RHEL: sudo yum install mariadb-server mariadb"
        echo "  Fedora: sudo dnf install mariadb-server mariadb"
        exit 1
    fi
    
    if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
        print_status "MariaDB service is running ✓"
    else
        print_warning "MariaDB service is not running. Attempting to start..."
        sudo systemctl start mariadb || sudo systemctl start mysql || {
            print_error "Failed to start MariaDB service!"
            echo "Please start MariaDB manually:"
            echo "  sudo systemctl start mariadb"
            exit 1
        }
        print_status "MariaDB service started ✓"
    fi
}

# Get MySQL root password
get_root_password() {
    echo ""
    echo "📋 Database Setup Information:"
    echo "  Database Name: $DB_NAME"
    echo "  Database User: $DB_USER"
    echo "  Database Password: $DB_PASSWORD"
    echo ""
    
    # Try to connect without password first
    if mysql -u root -e "SELECT 1;" >/dev/null 2>&1; then
        print_status "Root login without password successful"
        DB_ROOT_PASSWORD=""
    else
        echo -n "Enter MySQL/MariaDB root password: "
        read -s DB_ROOT_PASSWORD
        echo ""
        
        # Test the password
        if ! mysql -u root -p"$DB_ROOT_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; then
            print_error "Invalid root password!"
            exit 1
        fi
        print_status "Root password verified ✓"
    fi
}

# Create database and user
create_database() {
    print_header "Creating database and user..."
    
    # Prepare MySQL command
    MYSQL_CMD="mysql -u root"
    if [ ! -z "$DB_ROOT_PASSWORD" ]; then
        MYSQL_CMD="$MYSQL_CMD -p$DB_ROOT_PASSWORD"
    fi
    
    # Create database and user
    $MYSQL_CMD << EOF
-- Create database
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- Create user (drop if exists first)
DROP USER IF EXISTS '$DB_USER'@'localhost';
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';

-- Grant privileges
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;

-- Show created database
SHOW DATABASES LIKE '$DB_NAME';
EOF

    if [ $? -eq 0 ]; then
        print_status "Database '$DB_NAME' and user '$DB_USER' created successfully ✓"
    else
        print_error "Failed to create database or user!"
        exit 1
    fi
}

# Create notes table
create_table() {
    print_header "Creating notes table..."
    
    mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" << EOF
-- Create notes table
CREATE TABLE IF NOT EXISTS notes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    author VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Indexes for better performance
    INDEX idx_title (title),
    INDEX idx_author (author),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Show table structure
DESCRIBE notes;

-- Insert sample data
INSERT IGNORE INTO notes (id, title, content, author) VALUES 
(1, 'Welcome to Simple Note App', 'This is your first note! You can create, read, update, and delete notes using this simple application.\n\nFeatures:\n- Create new notes\n- View all notes\n- Search notes\n- Update existing notes\n- Delete notes\n\nEnjoy taking notes!', 'System'),
(2, 'Quick Start Guide', 'To get started:\n1. Run the frontend.py script\n2. Choose option 1 to create a new note\n3. Enter title, author, and content\n4. Use option 2 to view all your notes\n\nTip: Use option 4 to search through your notes quickly!', 'Admin');

-- Show inserted data
SELECT id, title, author, created_at FROM notes;
EOF

    if [ $? -eq 0 ]; then
        print_status "Notes table created successfully with sample data ✓"
    else
        print_error "Failed to create notes table!"
        exit 1
    fi
}

# Create environment file
create_env_file() {
    print_header "Creating environment configuration..."
    
    cat > "$(dirname "$0")/.env" << EOF
# Simple Note App Database Configuration
DB_HOST=localhost
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
DB_PORT=3306
EOF

    print_status "Environment file created: .env ✓"
    echo "  You can modify database settings in this file if needed."
}

# Install Python dependencies
install_python_deps() {
    print_header "Checking Python dependencies..."
    
    # Check if pip is available
    if ! command -v pip3 >/dev/null 2>&1; then
        print_warning "pip3 not found, trying pip..."
        if ! command -v pip >/dev/null 2>&1; then
            print_error "pip not found! Please install Python pip."
            exit 1
        fi
        PIP_CMD="pip"
    else
        PIP_CMD="pip3"
    fi
    
    # Install mysql-connector-python
    if python3 -c "import mysql.connector" 2>/dev/null; then
        print_status "mysql-connector-python already installed ✓"
    else
        print_status "Installing mysql-connector-python..."
        $PIP_CMD install mysql-connector-python
        if [ $? -eq 0 ]; then
            print_status "mysql-connector-python installed successfully ✓"
        else
            print_error "Failed to install mysql-connector-python!"
            echo "You can install it manually with: $PIP_CMD install mysql-connector-python"
        fi
    fi
}

# Test database connection
test_connection() {
    print_header "Testing database connection..."
    
    python3 << EOF
import mysql.connector
import os

try:
    conn = mysql.connector.connect(
        host='localhost',
        user='$DB_USER',
        password='$DB_PASSWORD',
        database='$DB_NAME',
        port=3306
    )
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM notes")
    count = cursor.fetchone()[0]
    print(f"✅ Connection successful! Found {count} notes in database.")
    cursor.close()
    conn.close()
except Exception as e:
    print(f"❌ Connection failed: {e}")
    exit(1)
EOF

    if [ $? -eq 0 ]; then
        print_status "Database connection test successful ✓"
    else
        print_error "Database connection test failed!"
        exit 1
    fi
}

# Main setup process
main() {
    echo "============================================"
    echo "🗒️  Simple Note App - Database Setup"
    echo "============================================"
    echo ""
    
    # Run setup steps
    check_mariadb
    get_root_password
    create_database
    create_table
    create_env_file
    install_python_deps
    test_connection
    
    echo ""
    echo "============================================"
    echo "🎉 Setup completed successfully!"
    echo "============================================"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Run the application: python3 frontend.py"
    echo "  2. Start creating notes!"
    echo ""
    echo "📁 Database details:"
    echo "  Host: localhost"
    echo "  Database: $DB_NAME"
    echo "  User: $DB_USER"
    echo "  Password: $DB_PASSWORD"
    echo ""
    echo "🔧 Configuration file: .env"
    echo "   (modify this file to change database settings)"
    echo ""
}

# Run main function
main "$@" 