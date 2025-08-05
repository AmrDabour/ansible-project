#!/bin/bash

# Simple Note App - SQLite Database Setup Script
# This script sets up SQLite database and creates the notes table

set -e  # Exit on any error

echo "Starting SQLite setup for Simple Note App..."

# Configuration variables
DB_FILE="notes.db"

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

# Check if SQLite is available
check_sqlite() {
    print_header "Checking SQLite installation..."
    
    if command -v sqlite3 >/dev/null 2>&1; then
        print_status "SQLite3 found"
    else
        print_error "SQLite3 not found!"
        echo "SQLite3 should be installed. Checking if it's available as sqlite..."
        if command -v sqlite >/dev/null 2>&1; then
            print_status "SQLite found"
        else
            print_error "SQLite not found! It should be installed by the Ansible playbook."
            exit 1
        fi
    fi
}

# Create SQLite database and table
create_database() {
    print_header "Creating SQLite database and table..."
    
    # Remove existing database if it exists (for clean setup)
    if [ -f "$DB_FILE" ]; then
        print_warning "Existing database found, backing up..."
        mv "$DB_FILE" "${DB_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Create database and table using SQLite
    sqlite3 "$DB_FILE" << EOF
-- Create notes table
CREATE TABLE IF NOT EXISTS notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    author TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO notes (title, content, author) VALUES 
('Welcome to Simple Note App', 'This is your first note! You can create, read, update, and delete notes using this simple application.

Features:
- Create new notes
- View all notes  
- Search notes
- Update existing notes
- Delete notes
- Beautiful interactive UI
- Drag and drop note cards

Enjoy taking notes!', 'System'),

('Quick Start Guide', 'To get started:
1. The web application is now running
2. Click the + button to create a new note
3. Fill in title, author, and content
4. Save your note and see it appear as a draggable card
5. Click on any note to view, edit, or delete it

Tips:
- Drag notes around the screen to organize them
- Use the search feature to find specific notes quickly!
- Notes are automatically saved to the SQLite database', 'Admin');

-- Show table structure
.schema notes

-- Show inserted data
SELECT id, title, author, created_at FROM notes;
EOF

    if [ $? -eq 0 ]; then
        print_status "SQLite database '$DB_FILE' created successfully"
        print_status "Notes table created with sample data"
    else
        print_error "Failed to create SQLite database!"
        exit 1
    fi
}

# Create environment file
create_env_file() {
    print_header "Creating environment configuration..."
    
    cat > "$(dirname "$0")/.env" << EOF
# Simple Note App Database Configuration
# Using SQLite - no additional configuration needed
DB_PATH=$DB_FILE
FLASK_PORT=5000
EOF

    print_status "Environment file created: .env"
    echo "  SQLite database path: $DB_FILE"
}

# Test database connection
test_connection() {
    print_header "Testing SQLite database..."
    
    if [ -f "$DB_FILE" ]; then
        # Test SQLite database by counting records
        record_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM notes;")
        if [ $? -eq 0 ]; then
            print_status "SQLite database test successful"
            print_status "Found $record_count notes in database"
        else
            print_error "Failed to query SQLite database!"
            exit 1
        fi
    else
        print_error "SQLite database file not found: $DB_FILE"
        exit 1
    fi
    
    # Test if database file is readable/writable
    if [ -r "$DB_FILE" ] && [ -w "$DB_FILE" ]; then
        print_status "Database file permissions are correct"
    else
        print_warning "Database file permissions may need adjustment"
        chmod 664 "$DB_FILE"
        print_status "Fixed database file permissions"
    fi
}

# Main setup process
main() {
    echo "============================================"
    echo "Simple Note App - SQLite Database Setup"
    echo "============================================"
    echo ""
    
    print_status "Database file: $DB_FILE"
    echo ""
    
    # Run setup steps
    check_sqlite
    create_database
    create_env_file
    test_connection
    
    echo ""
    echo "============================================"
    echo "Setup completed successfully!"
    echo "============================================"
    echo ""
    echo "Next steps:"
    echo "  1. The web application will start automatically"
    echo "  2. Access the app via your web browser"
    echo "  3. Start creating notes!"
    echo ""
    echo "Database details:"
    echo "  Type: SQLite"
    echo "  File: $DB_FILE"
    echo "  Location: $(pwd)/$DB_FILE"
    echo ""
    echo "Configuration file: .env"
    echo "   (modify this file to change app settings)"
    echo ""
}

# Run main function
main "$@" 