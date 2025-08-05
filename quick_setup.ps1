# Simple Note App - Quick Setup (Windows)
# Simplified version that works with XAMPP MySQL

Write-Host "🚀 Simple Note App - Quick Database Setup" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# Configuration
$DB_NAME = "simple_notes"
$DB_USER = "notes_user"
$DB_PASSWORD = "amr"

# Find MySQL client
$MySQLPath = $null
$possiblePaths = @(
    "C:\xampp\mysql\bin\mysql.exe",
    "C:\Program Files\MariaDB 11.8\bin\mysql.exe",
    "C:\Program Files\MariaDB 10.11\bin\mysql.exe",
    "C:\Program Files\MariaDB 10.10\bin\mysql.exe",
    "C:\Program Files (x86)\MariaDB 10.11\bin\mysql.exe",
    "C:\Program Files (x86)\MariaDB 10.10\bin\mysql.exe"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $MySQLPath = $path
        Write-Host "✅ Found MySQL: $path" -ForegroundColor Green
        break
    }
}

if (-not $MySQLPath) {
    Write-Host "❌ MySQL client not found!" -ForegroundColor Red
    exit 1
}

# Get root password
Write-Host "`n📋 Database Info:" -ForegroundColor Blue
Write-Host "  Database: $DB_NAME"
Write-Host "  User: $DB_USER"
Write-Host "  Password: $DB_PASSWORD"

$rootPassword = Read-Host "`nEnter MySQL root password (or press Enter if none)"

# Create SQL script file
$sqlScript = @"
CREATE DATABASE IF NOT EXISTS ``$DB_NAME`` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
DROP USER IF EXISTS '$DB_USER'@'localhost';
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON ``$DB_NAME``.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
USE $DB_NAME;
CREATE TABLE IF NOT EXISTS notes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    author VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
INSERT IGNORE INTO notes (id, title, content, author) VALUES 
(1, 'Welcome to Simple Note App', 'This is your first note! You can create, read, update, and delete notes using this simple application.\n\nFeatures:\n- Create new notes\n- View all notes\n- Search notes\n- Update existing notes\n- Delete notes\n\nEnjoy taking notes!', 'System'),
(2, 'Quick Start Guide', 'To get started:\n1. Run the frontend.py script\n2. Choose option 1 to create a new note\n3. Enter title, author, and content\n4. Use option 2 to view all your notes\n\nTip: Use option 4 to search through your notes quickly!', 'Admin');
SELECT 'Database setup completed!' as Status;
"@

# Save SQL script to temporary file
$tempSQL = "temp_setup.sql"
$sqlScript | Out-File -FilePath $tempSQL -Encoding UTF8

Write-Host "`n🔧 Setting up database..." -ForegroundColor Blue

try {
    if ([string]::IsNullOrEmpty($rootPassword)) {
        Get-Content $tempSQL | & $MySQLPath -u root
    }
    else {
        Get-Content $tempSQL | & $MySQLPath -u root -p"$rootPassword"
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Database setup successful!" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Database setup failed!" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    # Clean up temp file
    if (Test-Path $tempSQL) {
        Remove-Item $tempSQL
    }
}

# Create .env file
Write-Host "`n📄 Creating .env file..." -ForegroundColor Blue
$envContent = @"
DB_HOST=localhost
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
DB_PORT=3306
"@
$envContent | Out-File -FilePath ".env" -Encoding UTF8
Write-Host "✅ .env file created!" -ForegroundColor Green

# Install Python dependencies
Write-Host "`n📦 Installing Python dependencies..." -ForegroundColor Blue
try {
    pip install mysql-connector-python python-dotenv
    Write-Host "✅ Dependencies installed!" -ForegroundColor Green
}
catch {
    Write-Host "⚠️  Please install manually: pip install mysql-connector-python python-dotenv" -ForegroundColor Yellow
}

# Test connection
Write-Host "`n🧪 Testing database connection..." -ForegroundColor Blue
$testScript = @"
import mysql.connector
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
    print(f"✅ Connection successful! Found {count} notes.")
    cursor.close()
    conn.close()
except Exception as e:
    print(f"❌ Connection failed: {e}")
"@

try {
    $testScript | python
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Connection test successful!" -ForegroundColor Green
    }
}
catch {
    Write-Host "⚠️  Please test connection manually" -ForegroundColor Yellow
}

Write-Host "`n🎉 Setup Complete!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host "📋 Next steps:"
Write-Host "  1. Run: python frontend.py"
Write-Host "  2. Start creating notes!"
Write-Host "`n🔧 Database Details:"
Write-Host "  Host: localhost"
Write-Host "  Database: $DB_NAME"
Write-Host "  User: $DB_USER"
Write-Host "  Password: $DB_PASSWORD" 