# 📝 Simple Note-Taking App - Ansible Deployment

## 🎯 Project Overview
Simple Flask web application for taking notes with SQLite database, deployed using Ansible on Amazon Linux EC2.

## ✅ Requirements Met
- ✅ Python Flask web application
- ✅ SQLite database for storing notes  
- ✅ Simple interface for writing and viewing notes
- ✅ Notes displayed with timestamps
- ✅ Deployed on Amazon Linux EC2 via Ansible
- ✅ No complex templates or roles - just simple files

## 📁 Project Structure
```
control_server_files/
├── site.yml              # Main Ansible playbook (no roles!)
├── inventory/hosts        # Server inventory
├── files/
│   ├── app.py            # Simple Flask application (static file)
│   ├── requirements.txt  # Python dependencies
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
Open browser: `http://YOUR_WEB_SERVER_IP:8080`

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

## 📊 Features
- ✨ Write and save notes
- 📅 Automatic timestamps
- 📋 View all notes in chronological order  
- 💾 SQLite database storage
- 🔄 Auto-restart service
- 📦 Simple backup system

## 🏗️ Architecture
- **Frontend**: Simple HTML form in Flask
- **Backend**: Python Flask application
- **Database**: SQLite (file-based)
- **Server**: Amazon Linux with systemd service

No Apache, no complex templates, no roles - just the essentials! 🎯 