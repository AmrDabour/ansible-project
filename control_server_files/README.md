# Ansible Deployment for Note-Taking Web App

This directory contains Ansible configuration files to deploy a note-taking web application on AWS EC2.

## Files Structure
```
control_server_files/
├── ansible.cfg          # Ansible configuration
├── hosts               # Inventory file with target servers
├── Ansible.pem         # SSH private key for EC2 access
├── deploy_noteapp.yml  # Main deployment playbook
├── opposite.yml        # Cleanup playbook (removes everything)
├── verify_clean.yml    # Verify server is in clean state
├── vars.yml            # Single variables file with all configuration
└── README.md          # This file
```

## Configuration

All configuration is now centralized in the single `vars.yml` file. Key settings:
- Application Port: 5000 (configured for non-privileged access)
- Target Server: 98.84.54.112
- Application Directory: /opt/note_app
- Service Name: noteapp

To modify any settings, edit the `vars.yml` file.

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

### 3. Remove/Cleanup the Application (Opposite)
```bash
ansible-playbook opposite.yml
```

### 4. Verify Server is Clean
```bash
ansible-playbook verify_clean.yml
```

## What the Playbook Does

### deploy_noteapp.yml (Main Deployment)

1. Updates system packages
2. Installs Git, Python3, pip, and SQLite
3. Clones the GitHub repository: <https://github.com/AmrDabour/ansible-project.git>
4. Installs Python requirements from requirements.txt
5. Sets up the SQLite database
6. Creates a systemd service for the web app
7. Starts the application service
8. Configures firewall rules

### opposite.yml (Cleanup/Removal)

1. Stops and disables the noteapp service
2. Removes the systemd service file
3. Closes firewall ports that were opened
4. Removes the entire application directory
5. Uninstalls application-specific Python packages
6. Removes git package (keeps system essentials)
7. Cleans up Python cache files and directories
8. Returns the server to a plain, clean state

### verify_clean.yml (Verification)

1. Checks if application directory exists
2. Verifies service file is removed
3. Confirms service is not running
4. Displays firewall status
5. Reports overall cleanliness status

## Access Your Application

After successful deployment, access your note-taking app at:

- <http://98.84.54.112:5000> (current configuration)

## Troubleshooting
- Ensure your EC2 security group allows the required ports
- Check service status: `ansible webservers -m shell -a "sudo systemctl status noteapp"`
- View logs: `ansible webservers -m shell -a "sudo journalctl -u noteapp -f"`

## Commands Reference
- Test connectivity: `ansible webservers -m ping`
- Check service status: `ansible webservers -m systemd -a "name=noteapp" -b`
- Restart service: `ansible webservers -m systemd -a "name=noteapp state=restarted" -b`
