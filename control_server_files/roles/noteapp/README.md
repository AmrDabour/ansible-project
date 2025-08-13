# Simple Note App - Ansible Role

This role deploys the Simple Note App from GitHub to remote servers.

## What it does

- ✅ Installs required packages (git, python3, pip, sqlite)
- ✅ Clones the app from GitHub repository
- ✅ Installs Python dependencies
- ✅ Sets up SQLite database
- ✅ Creates systemd service
- ✅ Configures firewall
- ✅ Starts the application

## Variables

Default variables in `defaults/main.yml`:

```yaml
app_name: "simple_note_app"
app_dir: "/opt/{{ app_name }}"
app_user: "ec2-user"
app_port: 5000
repo_url: "https://github.com/AmrDabour/simple_note_app.git"
repo_branch: "main"
```

## Usage

Include this role in your playbook:

```yaml
- name: Deploy Simple Note App
  hosts: webservers
  become: yes
  roles:
    - noteapp
```

## Requirements

- Target server with internet access
- SSH access with sudo privileges
- Python 3 and pip (will be installed if missing)
