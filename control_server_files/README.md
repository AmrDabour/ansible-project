# Simple Note App - Ansible Deployment

Deploy Simple Note App from GitHub to remote servers using Ansible.

## Quick Start

### 1. Update Inventory
Edit `inventory/hosts` with your server details:
```ini
[webservers]
web1 ansible_host=YOUR_SERVER_IP ansible_user=ec2-user ansible_ssh_private_key_file=../Ansible.pem
```

### 2. Deploy
```bash
ansible-playbook -i inventory/hosts deploy.yml
```

## What it does

- ✅ Clones app from GitHub
- ✅ Installs Python dependencies
- ✅ Sets up SQLite database
- ✅ Creates systemd service
- ✅ Opens firewall ports
- ✅ Starts the application

## Access Your App

After deployment, access your app at:
```
http://YOUR_SERVER_IP:5000
```

## Files Structure

```
control_server_files/
├── deploy.yml              # Main deployment playbook
├── inventory/hosts         # Server inventory
├── ansible.cfg            # Ansible configuration
└── roles/noteapp/          # Application role
    ├── tasks/main.yml      # Deployment tasks
    ├── defaults/main.yml   # Default variables
    └── vars/main.yml       # Role variables
```
