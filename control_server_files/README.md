# Ansible Deployment for Note-Taking Web App

This directory contains Ansible configuration files to deploy a note-taking web application on AWS EC2.

## Files Structure
```
control_server_files/
├── ansible.cfg          # Ansible configuration
├── hosts               # Inventory file with target servers
├── Ansible.pem         # SSH private key for EC2 access
├── deploy_noteapp.yml  # Main deployment playbook
├── test_connection.yml # Connection test playbook
└── README.md          # This file
```

## Prerequisites
1. AWS EC2 instance running Amazon Linux 2
2. Security Group allowing ports 22 (SSH), 80 (HTTP), and 5000 (if needed)
3. The EC2 instance should be accessible via the provided private key

## Usage

### 1. Test Connection First
```bash
ansible-playbook test_connection.yml
```

### 2. Deploy the Application
```bash
ansible-playbook deploy_noteapp.yml
```

## What the Playbook Does
1. Updates system packages
2. Installs Git, Python3, pip, and SQLite
3. Clones the GitHub repository: https://github.com/AmrDabour/ansible-project.git
4. Installs Python requirements from requirements.txt
5. Sets up the SQLite database
6. Creates a systemd service for the web app
7. Starts the application service
8. Configures firewall rules

## Access Your Application
After successful deployment, access your note-taking app at:
- http://98.84.54.112 (if running on port 80)
- http://98.84.54.112:5000 (if running on port 5000)

## Troubleshooting
- Ensure your EC2 security group allows the required ports
- Check service status: `ansible webservers -m shell -a "sudo systemctl status noteapp"`
- View logs: `ansible webservers -m shell -a "sudo journalctl -u noteapp -f"`

## Commands Reference
- Test connectivity: `ansible webservers -m ping`
- Check service status: `ansible webservers -m systemd -a "name=noteapp" -b`
- Restart service: `ansible webservers -m systemd -a "name=noteapp state=restarted" -b`
