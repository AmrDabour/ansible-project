#!/bin/bash
# Copy all Ansible role files to controller

echo "🚀 Copying Ansible role files to controller..."

# Copy roles directory
echo "📁 Copying roles directory..."
scp -i Ansible.pem -r roles ec2-user@98.84.54.112:/home/ec2-user/

# Copy playbook files
echo "📄 Copying playbook files..."
scp -i Ansible.pem deploy_with_role.yml ec2-user@98.84.54.112:/home/ec2-user/
scp -i Ansible.pem opposite_with_role.yml ec2-user@98.84.54.112:/home/ec2-user/

# Copy configuration files
echo "⚙️ Copying configuration files..."
scp -i Ansible.pem ansible.cfg ec2-user@98.84.54.112:/home/ec2-user/
scp -i Ansible.pem hosts ec2-user@98.84.54.112:/home/ec2-user/

# Copy original files (for backup)
echo "💾 Copying original files..."
scp -i Ansible.pem deploy_noteapp.yml ec2-user@98.84.54.112:/home/ec2-user/
scp -i Ansible.pem opposite.yml ec2-user@98.84.54.112:/home/ec2-user/
scp -i Ansible.pem vars.yml ec2-user@98.84.54.112:/home/ec2-user/

echo "✅ All files copied to controller!"
echo ""
echo "📋 Usage on controller:"
echo "  # Deploy using role:"
echo "  ansible-playbook deploy_with_role.yml"
echo ""
echo "  # Cleanup using role:"
echo "  ansible-playbook opposite_with_role.yml"
echo ""
echo "  # Deploy using original method:"
echo "  ansible-playbook deploy_noteapp.yml"
