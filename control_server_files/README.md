# 📝 DevOps Project: Note-Taking Web App on AWS EC2

## 🎯 Project Overview

This project deploys a note-taking web application on Amazon Linux EC2 using Ansible roles, featuring SQLite database integration and automated backup strategy.

### 🏗️ Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                   AWS EC2 Instance                         │
│                  (Amazon Linux 2)                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Apache    │  │   Python    │  │       SQLite        │  │
│  │   HTTP      │◄─┤    Flask    │◄─┤     Database        │  │
│  │   Port 80   │  │ Application │  │   /opt/noteapp/     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │           Automated Backup System                      │  │
│  │  • Daily database backups (2:00 AM)                   │  │
│  │  • Weekly application backups (Sunday 3:30 AM)        │  │
│  │  • Log rotation and retention                          │  │
│  └─────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Features

### ✅ **Application Features**
- **Simple Note Interface**: Clean, responsive web UI
- **SQLite Database**: Lightweight, serverless database
- **Timestamp Tracking**: Automatic note creation timestamps  
- **Real-time Display**: Notes appear immediately after submission
- **Health Check Endpoint**: `/health` for monitoring

### ✅ **Infrastructure Features**
- **Ansible Roles**: Modular, reusable automation
- **Amazon Linux Support**: Optimized for AWS EC2
- **Apache HTTP Server**: Production web server on port 80
- **Systemd Integration**: Service management and auto-restart
- **Firewall Configuration**: Secure SSH and HTTP access

### ✅ **Backup Strategy**
- **Daily Database Backups**: SQLite database preservation
- **Weekly Application Backups**: Complete application state
- **Retention Policy**: Automated cleanup of old backups
- **Restore Scripts**: Easy recovery procedures
- **Log Rotation**: System log management

## 🚀 Quick Start

### 1. **Prerequisites**

**AWS Setup:**
- EC2 instance (t2.micro) with Amazon Linux 2
- Security groups: SSH (22), HTTP (80)
- SSH key pair for access

**Local Setup:**
```bash
# Install Ansible (on your control machine)
sudo yum install epel-release -y
sudo yum install ansible -y

# Or on Ubuntu/Debian:
sudo apt update && sudo apt install ansible -y
```

### 2. **Configuration**

**Update Inventory:**
```bash
# Edit inventory/hosts with your EC2 details
nano control_server_files/inventory/hosts

# Replace with your actual values:
YOUR_EC2_IP_ADDRESS ansible_user=ec2-user ansible_ssh_private_key_file=/path/to/your-key.pem
```

### 3. **Deployment**

```bash
# Navigate to project directory
cd control_server_files/

# Test connectivity
./deploy_noteapp.sh ping

# Full deployment
./deploy_noteapp.sh deploy

# Check deployment status
./deploy_noteapp.sh status
```

### 4. **Access Application**

Open your browser and navigate to:
```
http://YOUR_EC2_IP_ADDRESS
```

## 📁 Project Structure

```
control_server_files/
├── site.yml                    # Main Ansible playbook
├── deploy_noteapp.sh           # Deployment automation script
├── inventory/
│   └── hosts                   # EC2 instance configuration
├── ansible.cfg                 # Ansible settings
├── roles/
│   ├── common/                 # System setup role
│   │   ├── tasks/main.yml
│   │   └── handlers/main.yml
│   ├── database/               # SQLite setup role
│   │   ├── tasks/main.yml
│   │   └── templates/
│   │       └── init_db.sql.j2
│   ├── webapp/                 # Flask application role
│   │   ├── tasks/main.yml
│   │   ├── handlers/main.yml
│   │   └── templates/
│   │       ├── app.py.j2
│   │       ├── requirements.txt.j2
│   │       ├── noteapp.service.j2
│   │       ├── noteapp.conf.j2
│   │       └── app.wsgi.j2
│   └── backup/                 # Backup strategy role
│       ├── tasks/main.yml
│       └── templates/
│           ├── backup_database.sh.j2
│           ├── backup_application.sh.j2
│           ├── restore_backup.sh.j2
│           └── noteapp_logrotate.j2
└── README.md                   # This documentation
```

## 🛠️ Deployment Commands

### **Core Commands**
```bash
# Full deployment (installs everything)
./deploy_noteapp.sh deploy

# Dry-run (see what would change)
./deploy_noteapp.sh check

# Test EC2 connectivity
./deploy_noteapp.sh ping

# Check application status
./deploy_noteapp.sh status
```

### **Component-Specific Deployment**
```bash
# System setup only
./deploy_noteapp.sh setup

# Database setup only  
./deploy_noteapp.sh database

# Web application only
./deploy_noteapp.sh webapp

# Backup system only
./deploy_noteapp.sh backup
```

### **Verbose Output**
```bash
# Standard verbose
./deploy_noteapp.sh deploy -v

# Extra verbose (debug)
./deploy_noteapp.sh deploy -vv
```

## 🗄️ Database Schema

The SQLite database contains a simple `notes` table:

```sql
CREATE TABLE notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**Sample Data:**
```
ID | Content                                      | Timestamp
---|----------------------------------------------|-------------------
1  | Don't forget to review the IAM policy...     | 2024-12-01 21:15:07
2  | Meeting notes from DevOps discussion        | 2024-12-01 21:20:15
```

## 📦 Backup System

### **Automated Backups**
- **Database**: Daily at 2:00 AM (retains 7 days)
- **Application**: Weekly on Sunday at 3:30 AM (retains 4 weeks)
- **Logs**: Daily rotation (retains 30 days)

### **Manual Backup Commands**
```bash
# SSH to your EC2 instance
ssh -i your-key.pem ec2-user@YOUR_EC2_IP

# Manual database backup
/opt/noteapp/backups/backup_database.sh

# Manual application backup
/opt/noteapp/backups/backup_application.sh

# Check backup status
/opt/noteapp/backups/check_backup_status.sh
```

### **Restore Procedures**
```bash
# Restore latest database backup
/opt/noteapp/backups/restore_backup.sh database latest

# Restore specific database backup
/opt/noteapp/backups/restore_backup.sh database notes_backup_20241201_120000.db

# Restore latest application backup
/opt/noteapp/backups/restore_backup.sh application latest
```

## 🔧 Application Management

### **Service Management**
```bash
# Check service status
sudo systemctl status noteapp httpd

# Restart services
sudo systemctl restart noteapp httpd

# View logs
sudo journalctl -u noteapp -f
```

### **Application Logs**
```bash
# Application logs
tail -f /opt/noteapp/logs/app.log

# Apache logs
tail -f /opt/noteapp/logs/apache_access.log
tail -f /opt/noteapp/logs/apache_error.log

# Backup logs
tail -f /opt/noteapp/logs/backup.log
```

### **Database Access**
```bash
# Connect to SQLite database
sqlite3 /opt/noteapp/database/notes.db

# Common queries
sqlite> .tables
sqlite> SELECT * FROM notes ORDER BY timestamp DESC LIMIT 10;
sqlite> .quit
```

## 🛠️ Troubleshooting

### **Common Issues**

**1. EC2 Connection Failed**
```bash
# Test manual SSH connection
ssh -i your-key.pem ec2-user@YOUR_EC2_IP

# Check security groups allow SSH (port 22)
# Verify key file permissions: chmod 600 your-key.pem
```

**2. Application Not Accessible**
```bash
# Check if services are running
./deploy_noteapp.sh status

# Verify firewall rules
sudo firewall-cmd --list-all

# Check if port 80 is open in EC2 security groups
```

**3. Database Issues**
```bash
# Check database file exists
ls -la /opt/noteapp/database/notes.db

# Verify permissions
sudo chown webapp:webapp /opt/noteapp/database/notes.db

# Test database connection
sqlite3 /opt/noteapp/database/notes.db "SELECT COUNT(*) FROM notes;"
```

**4. Ansible Deployment Issues**
```bash
# Run in check mode to see what would change
./deploy_noteapp.sh check -vv

# Test connectivity
./deploy_noteapp.sh ping

# Check Ansible inventory
ansible-inventory -i inventory/hosts --list
```

### **Health Checks**
```bash
# Application health endpoint
curl http://YOUR_EC2_IP/health

# Expected response:
# {"status": "healthy", "database": "connected"}
```

### **Log Analysis**
```bash
# Recent application errors
sudo journalctl -u noteapp --since "1 hour ago"

# Apache error logs
sudo tail -f /var/log/httpd/error_log

# System messages
sudo tail -f /var/log/messages
```

## 🔒 Security Features

### **Application Security**
- **Input Validation**: SQL injection prevention
- **HTTP Security Headers**: XSS protection, content type sniffing
- **SELinux Integration**: Security context management
- **Service Isolation**: Dedicated user and permissions

### **Infrastructure Security**
- **Firewall Rules**: Only SSH (22) and HTTP (80) open
- **User Separation**: Dedicated application user
- **File Permissions**: Restricted access to sensitive files
- **Log Monitoring**: Comprehensive logging and rotation

## 📊 Performance & Monitoring

### **Key Metrics to Monitor**
- **Application Response Time**: `/health` endpoint
- **Database Size**: SQLite file growth
- **Log File Sizes**: Disk space usage
- **Backup Success**: Daily/weekly backup status

### **Monitoring Commands**
```bash
# System resources
htop
df -h

# Application metrics
curl -s http://YOUR_EC2_IP/health | python3 -m json.tool

# Service status
systemctl is-active noteapp httpd
```

## 🚀 Next Steps & Enhancements

### **Potential Improvements**
1. **HTTPS Support**: SSL certificate integration
2. **Load Balancing**: Multiple EC2 instances
3. **Database Migration**: PostgreSQL or RDS
4. **Containerization**: Docker deployment
5. **CI/CD Pipeline**: Automated deployments
6. **Monitoring**: CloudWatch integration
7. **Scaling**: Auto Scaling Groups

### **Advanced Features**
- User authentication and authorization
- Note categories and tags
- Search functionality
- Export capabilities
- Real-time collaboration

---

## 📞 Support

### **Getting Help**
1. **Check Logs**: Application and system logs for errors
2. **Run Diagnostics**: Use `./deploy_noteapp.sh status` 
3. **Verify Configuration**: Ensure EC2 settings are correct
4. **Test Components**: Use individual role deployment

### **Project Submission Checklist**
- [ ] EC2 instance created (t2.micro, Amazon Linux)
- [ ] Security groups configured (SSH:22, HTTP:80)
- [ ] Application deployed via Ansible roles
- [ ] SQLite database functional
- [ ] Notes can be created and displayed
- [ ] Backup strategy implemented
- [ ] Documentation complete

---

**Project Version**: 1.0  
**Last Updated**: December 1, 2024  
**Compatible With**: Amazon Linux 2, Ansible 2.9+ 