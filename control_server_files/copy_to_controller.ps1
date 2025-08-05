# Copy all Ansible role files to controller

Write-Host "Copying Ansible role files to controller..." -ForegroundColor Green

# Copy roles directory
Write-Host "Copying roles directory..." -ForegroundColor Blue
& scp -i Ansible.pem -r roles ec2-user@98.84.54.112:/home/ec2-user/

# Copy playbook files
Write-Host "Copying playbook files..." -ForegroundColor Blue
& scp -i Ansible.pem deploy_with_role.yml ec2-user@98.84.54.112:/home/ec2-user/
& scp -i Ansible.pem opposite_with_role.yml ec2-user@98.84.54.112:/home/ec2-user/

# Copy configuration files
Write-Host "Copying configuration files..." -ForegroundColor Blue
& scp -i Ansible.pem ansible.cfg ec2-user@98.84.54.112:/home/ec2-user/
& scp -i Ansible.pem hosts ec2-user@98.84.54.112:/home/ec2-user/

# Copy original files (for backup)
Write-Host "Copying original files..." -ForegroundColor Blue
& scp -i Ansible.pem deploy_noteapp.yml ec2-user@98.84.54.112:/home/ec2-user/
& scp -i Ansible.pem opposite.yml ec2-user@98.84.54.112:/home/ec2-user/
& scp -i Ansible.pem vars.yml ec2-user@98.84.54.112:/home/ec2-user/

Write-Host "All files copied to controller!" -ForegroundColor Green
Write-Host ""
Write-Host "Usage on controller:" -ForegroundColor Yellow
Write-Host "  # Deploy using role:" -ForegroundColor White
Write-Host "  ansible-playbook deploy_with_role.yml" -ForegroundColor Cyan
Write-Host ""
Write-Host "  # Cleanup using role:" -ForegroundColor White
Write-Host "  ansible-playbook opposite_with_role.yml" -ForegroundColor Cyan
Write-Host ""
Write-Host "  # Deploy using original method:" -ForegroundColor White
Write-Host "  ansible-playbook deploy_noteapp.yml" -ForegroundColor Cyan
