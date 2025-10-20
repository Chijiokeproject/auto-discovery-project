#!/bin/bash

# install SSM
dnf install -y "https://s3.${region}.amazonaws.com/amazon-ssm-${region}/latest/linux_amd64/amazon-ssm-agent.rpm"
curl -O "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm"
yum install -y session-manager-plugin.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Create SSH directory for ec2-user
mkdir -p /home/ec2-user/.ssh
# Copy the private key into the .ssh directory
echo "${private_key}" > /home/ec2-user/.ssh/id_rsa
# Set correct permissions and ownership
chmod 400 /home/ec2-user/.ssh/id_rsa
chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa

# Set hostname
hostnamectl set-hostname bastion

# Install New Relic
curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && \
sudo NEW_RELIC_API_KEY="${nr_key}" \
     NEW_RELIC_ACCOUNT_ID="${nr_acc_id}" \
     NEW_RELIC_REGION=EU \
     /usr/local/bin/newrelic install -y