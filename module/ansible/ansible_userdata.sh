#!/bin/bash

# Updating instance
sudo yum update -y
sudo yum install wget unzip -y
sudo bash -c "echo 'StrictHostKeyChecking No' >> /etc/ssh/ssh_config"

# Installing awscli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo ln -svf /usr/local/bin/aws /usr/bin/aws

# Installing ansible
sudo yum install -y ansible-core
sudo yum update -y

# Ensure playbook directory exists
sudo mkdir -p /etc/ansible/playbook

# Copy private key
echo "${private_key}" | sudo tee /home/ec2-user/.ssh/id_rsa > /dev/null
sudo chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa
sudo chmod 400 /home/ec2-user/.ssh/id_rsa

# Pull scripts from S3 bucket
aws s3 cp s3://auto-s3-bucket-12345/ansible/playbook/prod-bash.sh /etc/ansible/playbook/prod-bash.sh
aws s3 cp s3://auto-s3-bucket-12345/ansible/playbook/stage-bash.sh /etc/ansible/playbook/stage-bash.sh
aws s3 cp s3://auto-s3-bucket-12345/ansible/playbook/deployment.yml /etc/ansible/playbook/deployment.yml

# Create ansible variable file
sudo bash -c "echo 'NEXUS_IP: ${nexus_ip}:8085' > /etc/ansible/ansible_vars_file.yml"
sudo chown -R ec2-user:ec2-user /etc/ansible
sudo chmod 755 /etc/ansible/playbook/prod-bash.sh
sudo chmod 755 /etc/ansible/playbook/stage-bash.sh

# Creating cron jobs safely
sudo tee /etc/cron.d/ansible_jobs > /dev/null <<EOF
* * * * * ec2-user sh /etc/ansible/playbook/prod-bash.sh
* * * * * ec2-user sh /etc/ansible/playbook/stage-bash.sh
EOF

# Install New Relic
curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && \
sudo NEW_RELIC_API_KEY="${nr_key}" NEW_RELIC_ACCOUNT_ID="${nr_acc_id}" NEW_RELIC_REGION=EU /usr/local/bin/newrelic install -y

sudo hostnamectl set-hostname ansible-server
