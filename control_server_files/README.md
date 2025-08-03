# 🚀 Advanced Note-Taking App - Ansible Deployment

## 🎯 Project Overview
Advanced interactive Flask web application with draggable note cards, beautiful animations, and SQLite database, deployed using Ansible on Amazon Linux EC2.

## ✅ Requirements Met
- ✅ Advanced Python Flask web application with interactive UI
- ✅ SQLite database with enhanced schema (title, author, content)
- ✅ Beautiful interface with draggable note cards
- ✅ Notes displayed with timestamps and full metadata
- ✅ Deployed on Amazon Linux EC2 via Ansible on port 80
- ✅ Advanced features: animations, search, CRUD operations

## 📁 Project Structure
```
control_server_files/
├── site.yml              # Main Ansible playbook (no roles!)
├── inventory/hosts        # Server inventory
├── files/
│   ├── frontend.py       # Advanced Flask application with interactive UI
│   ├── requirements.txt  # Python dependencies (Flask, python-dotenv)
│   └── backup.sh         # Simple backup script
├── deploy_simple.sh      # Deployment script
└── README.md            # This file
```

## 🚀 Quick Deployment

### 1. Update Inventory
Edit `inventory/hosts` with your web server IP:
```ini
[noteapp_servers]
YOUR_WEB_SERVER_IP ansible_user=ec2-user ansible_ssh_private_key_file=/path/to/key.pem
```

### 2. Run Deployment
```bash
cd control_server_files/
chmod +x deploy_simple.sh
./deploy_simple.sh
```

### 3. Access Application
Open browser: `http://YOUR_WEB_SERVER_IP` (port 80)

## 🛠️ What Gets Deployed
- Python 3 + Flask installation
- SQLite database setup
- Simple note-taking web interface  
- Systemd service for auto-start
- Basic firewall configuration

## 🔧 Application Management
```bash
# Check service status
sudo systemctl status noteapp

# View logs
sudo journalctl -u noteapp -f

# Restart service
sudo systemctl restart noteapp

# Manual backup
sudo /opt/noteapp/backup.sh
```

## 🌟 Advanced Features
- ✨ Interactive floating note cards with drag & drop
- 🎨 Beautiful animations and real-time effects  
- 📝 Full note editor with title, author, and content
- 🔍 Real-time search functionality
- 📅 Automatic timestamps and metadata
- 💾 Enhanced SQLite database with full schema
- 🎭 Interactive background with polygon creation
- 📱 Responsive design for all devices
- 🔄 Auto-restart service
- 🛡️ Full CRUD operations via REST API

## 🏗️ Architecture
- **Frontend**: Simple HTML form in Flask
- **Backend**: Python Flask application
- **Database**: SQLite (file-based)
- **Server**: Amazon Linux with systemd service

No Apache, no complex templates, no roles - just the essentials! 🎯 