#!/bin/bash

# Simple Note App - Ansible Deployment Script

echo "🚀 Deploying Simple Note App with Ansible..."
echo "=============================================="

# Check if inventory exists
if [ ! -f "inventory/hosts" ]; then
    echo "❌ Error: inventory/hosts not found!"
    echo "Please update inventory/hosts with your server details."
    exit 1
fi

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo "❌ Error: ansible-playbook not found!"
    echo "Please install Ansible first:"
    echo "pip install ansible"
    exit 1
fi

# Run the deployment
echo "📋 Running Ansible playbook..."
ansible-playbook -i inventory/hosts deploy.yml

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment completed successfully!"
    echo "🌐 Your app should be accessible at: http://YOUR_SERVER_IP:5000"
else
    echo ""
    echo "❌ Deployment failed!"
    echo "Check the error messages above for details."
fi 