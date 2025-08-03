# 🚀 Simple Note App - Ansible Deployment

This directory contains a complete Ansible automation system for deploying the Simple Note App across multiple servers with separation of concerns (web server + database server).

## 📋 File Structure

```
control_server_files/
├── deploy.yml                 # Main Ansible playbook
├── deploy.sh                  # Deployment automation script
├── hosts                      # Original inventory file
├── inventory.yml              # Enhanced YAML inventory
├── ansible.cfg                # Ansible configuration
├── vars/
│   └── main.yml              # Variables and configuration
└── templates/
    ├── env.j2                # Flask app environment template
    └── simple-note-app.service.j2  # Systemd service template
```

## 🏗️ Infrastructure Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Controller     │    │   Web Server    │    │  Database       │
│  Server         │───▶│  3.221.163.59   │───▶│  Server         │
│  (Ansible)      │    │  - Flask App    │    │  35.175.123.232 │
│                 │    │  - Python 3     │    │  - MariaDB      │
│                 │    │  - Systemd      │    │  - Remote Access│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🎯 What Gets Deployed

### Database Server (35.175.123.232)
- ✅ **MariaDB Server** - Complete database installation
- ✅ **Database Creation** - `simple_notes` database
- ✅ **User Management** - Application-specific database user
- ✅ **Remote Access** - Configured for web server connection
- ✅ **Firewall Rules** - Port 3306 opened securely
- ✅ **Security** - Root password set and secured

### Web Server (3.221.163.59)
- ✅ **Python Environment** - Python 3, pip, virtual environment
- ✅ **Application Code** - Cloned from GitHub repository
- ✅ **Dependencies** - All Python packages from requirements.txt
- ✅ **Configuration** - Auto-generated .env file
- ✅ **Systemd Service** - Application runs as system service
- ✅ **Auto-restart** - Service restarts on failure
- ✅ **Firewall Rules** - Port 5000 opened for web access

## 🚀 Quick Start

### 1. Prerequisites (Controller Server)

```bash
# Install Ansible
sudo yum install epel-release -y
sudo yum install ansible -y

# Or on Ubuntu/Debian:
sudo apt update
sudo apt install ansible -y

# Verify installation
ansible --version
```

### 2. Basic Deployment

```bash
# Test connectivity
./deploy.sh ping

# Full deployment (recommended)
./deploy.sh deploy

# Or with verbose output
./deploy.sh deploy -v
```

### 3. Verify Deployment

```bash
# Check application status
./deploy.sh status

# View application logs  
./deploy.sh logs

# Test the application
curl http://3.221.163.59:5000
```

## 📖 Deployment Commands

### Core Deployment Commands

```bash
# Full deployment (database + web server)
./deploy.sh deploy

# Deploy only database server
./deploy.sh db-only

# Deploy only web server
./deploy.sh web-only

# Dry-run deployment (check what would change)
./deploy.sh check
```

### Management Commands

```bash
# Test server connectivity
./deploy.sh ping

# Initialize/setup database tables
./deploy.sh setup-db

# Restart application service
./deploy.sh restart-app

# Check application status
./deploy.sh status

# View application logs (last 50 lines)
./deploy.sh logs
```

### Advanced Options

```bash
# Verbose output
./deploy.sh deploy -v

# Extra verbose output
./deploy.sh deploy -vv

# Use custom inventory
./deploy.sh deploy -i custom_inventory

# Run specific tags only
./deploy.sh deploy --tags database

# Skip specific tags
./deploy.sh deploy --skip-tags web
```

## ⚙️ Configuration

### Variables (vars/main.yml)

Key configuration options you can customize:

```yaml
# Application Settings
app_port: 5000
git_repo_url: "https://github.com/AmrDabour/ansible-project.git"
git_branch: "master"

# Database Settings
mysql_root_password: "SecureRootPassword123!"
db_name: "simple_notes"
db_user: "notes_user"
db_password: "notes_password"

# Performance Settings
gunicorn_workers: 3
gunicorn_timeout: 30
```

### Inventory Configuration

Update `hosts` or `inventory.yml` to match your servers:

```ini
# hosts file format
[web]
YOUR_WEB_SERVER_IP ansible_user=ec2-user ansible_ssh_private_key_file=/path/to/key.pem

[db]  
YOUR_DB_SERVER_IP ansible_user=ec2-user ansible_ssh_private_key_file=/path/to/key.pem
```

## 🔧 Customization Examples

### 1. Change Application Port

```yaml
# In vars/main.yml
app_port: 8080
```

### 2. Use Different Git Branch

```yaml
# In vars/main.yml
git_branch: "development"
```

### 3. Enable SSL

```yaml
# In vars/main.yml
ssl_enabled: true
ssl_cert_path: "/etc/ssl/certs/app.crt"
ssl_key_path: "/etc/ssl/private/app.key"
```

### 4. Change Database Password

```yaml
# In vars/main.yml
mysql_root_password: "YourNewSecurePassword"
db_password: "YourAppPassword"
```

## 🛠️ Troubleshooting

### Common Issues

**1. SSH Connection Failed**
```bash
# Test SSH manually
ssh -i /path/to/ansible.pem ec2-user@SERVER_IP

# Check SSH key permissions
chmod 600 /path/to/ansible.pem
```

**2. Database Connection Failed**
```bash
# Check MariaDB status on DB server
ssh -i ansible.pem ec2-user@DB_SERVER_IP
sudo systemctl status mariadb

# Test database connection from web server
mysql -h DB_SERVER_IP -u notes_user -p
```

**3. Application Not Starting**
```bash
# Check service status
./deploy.sh status

# View detailed logs
./deploy.sh logs

# Restart application
./deploy.sh restart-app
```

**4. Firewall Issues**
```bash
# Check firewall status (on target servers)
sudo firewall-cmd --list-all     # RHEL/CentOS
sudo ufw status                  # Ubuntu
```

### Debug Mode

Run deployment in check mode to see what would change:

```bash
./deploy.sh check -vv
```

### Manual Verification

```bash
# Check if application is running
curl http://WEB_SERVER_IP:5000

# Check database connectivity
mysql -h DB_SERVER_IP -u notes_user -p simple_notes
```

## 📊 Monitoring & Maintenance

### Application Health Check

```bash
# Automated health check
./deploy.sh status

# Manual verification
curl -f http://3.221.163.59:5000 && echo "✅ App is healthy"
```

### Service Management

```bash
# Restart application
sudo systemctl restart simple-note-app

# Check service status
sudo systemctl status simple-note-app

# View service logs
sudo journalctl -u simple-note-app -f
```

### Database Maintenance

```bash
# Connect to database
mysql -h 35.175.123.232 -u notes_user -p simple_notes

# Check database status
SHOW TABLES;
SELECT COUNT(*) FROM notes;
```

## 🔒 Security Considerations

### 1. SSH Keys
- Ensure SSH private keys have proper permissions (600)
- Use different keys for different environments
- Rotate keys regularly

### 2. Database Security
- Change default passwords in `vars/main.yml`
- Use strong passwords (minimum 12 characters)
- Restrict database access to application servers only

### 3. Firewall Rules
- Only necessary ports are opened (3306 for DB, 5000 for web)
- Consider using VPN or private networks for database connections

### 4. Application Security
- Update `secret_key` in `vars/main.yml`
- Consider enabling SSL for production use
- Regular security updates via package management

## 🚀 Production Deployment Checklist

- [ ] Update all passwords in `vars/main.yml`
- [ ] Configure proper SSL certificates
- [ ] Set up monitoring and alerting
- [ ] Configure automated backups
- [ ] Test disaster recovery procedures
- [ ] Update firewall rules for production
- [ ] Configure log rotation
- [ ] Set up proper DNS records

## 📞 Support & Troubleshooting

### Log Locations

- **Application Logs**: `/opt/simple-note-app/logs/app.log`
- **Service Logs**: `journalctl -u simple-note-app`
- **Database Logs**: `/var/log/mariadb/mariadb.log`
- **Ansible Logs**: Set `log_path` in `ansible.cfg`

### Useful Commands

```bash
# Full system check
./deploy.sh ping && ./deploy.sh status

# Redeploy after code changes
./deploy.sh web-only

# Database maintenance
./deploy.sh setup-db

# Emergency restart
./deploy.sh restart-app
```

---

**Last Updated**: December 1, 2024  
**Version**: 1.0  
**Supported OS**: RHEL/CentOS 7+, Ubuntu 18.04+, Amazon Linux 2 