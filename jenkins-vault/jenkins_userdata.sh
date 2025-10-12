#!/bin/bash
set -euo pipefail

#!/bin/bash
set -euo pipefail

# Simple idempotent RHEL/CentOS user-data for Jenkins box (no Terraform interpolation)
LOG=/var/log/jenkins-userdata.log
exec > >(tee -a "$LOG") 2>&1

echo "jenkins userdata start: $(date -u)"

sudo yum makecache -y || true
sudo yum install -y wget curl unzip jq yum-utils || true

# Java
if ! command -v java >/dev/null 2>&1; then
  sudo yum install -y java-17-openjdk || true
fi

# Maven
if ! command -v mvn >/dev/null 2>&1; then
  sudo yum install -y maven || true
fi

# Jenkins
if ! rpm -q jenkins >/dev/null 2>&1; then
  sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
  sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key || true
  sudo yum install -y jenkins || true
  sudo systemctl daemon-reload || true
  sudo systemctl enable --now jenkins || true
else
  sudo systemctl restart jenkins || true
fi

# Docker
if ! command -v docker >/dev/null 2>&1; then
  sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || true
  sudo yum install -y docker-ce docker-ce-cli containerd.io || true
  sudo systemctl enable --now docker || true
  sudo usermod -aG docker jenkins || true
fi

# Nexus OSS (lightweight install)
if [ ! -d /opt/sonatype-nexus ]; then
  sudo useradd -r -s /sbin/nologin nexus || true
  sudo mkdir -p /opt/sonatype-work /opt/sonatype-nexus || true
  curl -sSL https://download.sonatype.com/nexus/3/latest-unix.tar.gz -o /tmp/nexus.tar.gz || true
  sudo tar xzf /tmp/nexus.tar.gz -C /opt || true
  EXDIR=$(ls -d /opt/sonatype-nexus-* 2>/dev/null | head -n1 || true)
  if [ -n "$EXDIR" ]; then
    sudo ln -sfn "$EXDIR" /opt/sonatype-nexus || true
    sudo chown -R nexus:nexus "$EXDIR" /opt/sonatype-work || true
    cat <<'EOF' | sudo tee /etc/systemd/system/nexus.service
[Unit]
Description=Nexus Repository
After=network.target

[Service]
Type=forking
User=nexus
ExecStart=/opt/sonatype-nexus/bin/nexus start
ExecStop=/opt/sonatype-nexus/bin/nexus stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload || true
    sudo systemctl enable --now nexus || true
  fi
fi

# Trivy
if ! command -v trivy >/dev/null 2>&1; then
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh || true
fi

# AWS CLI v2
if ! command -v aws >/dev/null 2>&1; then
  curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -o /tmp/awscliv2.zip -d /tmp || true
  sudo /tmp/aws/install -i /usr/local/aws-cli -b /usr/local/bin || true
fi

# Session Manager Plugin
if ! command -v session-manager-plugin >/dev/null 2>&1; then
  curl -sS https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm -o /tmp/session-manager-plugin.rpm || true
  sudo yum install -y /tmp/session-manager-plugin.rpm || true
fi

# SSM Agent
if ! systemctl list-unit-files | grep -q amazon-ssm-agent; then
  SSM_URL="https://s3.amazonaws.com/amazon-ssm-agent/latest/linux_amd64/amazon-ssm-agent.rpm"
  if curl -sSfL "$SSM_URL" -o /tmp/amazon-ssm-agent.rpm; then
    sudo yum install -y /tmp/amazon-ssm-agent.rpm || true
  fi
fi
sudo systemctl daemon-reload || true
sudo systemctl enable --now amazon-ssm-agent || true

for i in 1 2 3 4 5; do
  if systemctl is-active --quiet amazon-ssm-agent; then
    echo "amazon-ssm-agent active"
    break
  fi
  sleep 6
done

echo "jenkins userdata finished: $(date -u)"
  # Session Manager Plugin
