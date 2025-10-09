# #!/bin/bash
# set -e

# # System Update
# sudo yum update -y

# # Install maven,git, wget, java, docker
# echo "📦 Installing dependencies: git, wget, java, maven, docker..."
# sudo yum install -y git wget maven java-11-amazon-corretto docker

# # Start and Enable Docker
# sudo systemctl enable docker
# sudo systemctl start docker

# # install ssm agent
# sudo yum install -y amazon-ssm-agent
# sudo systemctl enable amazon-ssm-agent
# sudo systemctl start amazon-ssm-agent

# # install trivy for scanning docker images
# curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin
# sudo trivy --version

# # Install Jenkins
# echo "🧰 Installing Jenkins..."
# sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
# sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
# sudo yum install -y jenkins

# sudo systemctl enable jenkins
# sudo systemctl start jenkins

# # Add Users to Docker Group
# echo "👥 Adding ec2-user and jenkins to docker group..."
# sudo usermod -aG docker ec2-user
# sudo usermod -aG docker jenkins
# sudo systemctl restart docker
# sudo systemctl restart jenkins

# sudo systemctl restart jenkins

# # Installing awscli
# sudo yum update
# sudo yum install unzip curl -y
# curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# unzip awscliv2.zip
# sudo ./aws/install

# #  install newrelic agent
# curl -Ls https://download.newrelic.com/install/newrelic-cli/scipts/install.sh | bash && sudo NEW_RELIC_API_KEY="${nr_key}" NEW_RELIC_ACCOUNT_ID="${nr_acct_id}" NEW_RELIC_REGION=EU /usr/local/bin/newrelic install -y
# sudo hostnamectl set-hostname jenkins




