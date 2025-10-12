#!/bin/bash
set -e

# Variables from Terraform
REGION="${var1}"        # e.g., eu-west-3
KMS_KEY_ID="${var2}"    # KMS key ARN or ID

# Update and install dependencies
apt-get update -y
apt-get install -y unzip jq curl gnupg software-properties-common

# Install Vault
VAULT_VERSION="1.14.1"
cd /tmp
curl -O https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip
unzip vault_${VAULT_VERSION}_linux_amd64.zip
mv vault /usr/local/bin/
chmod +x /usr/local/bin/vault
vault -v

# Create Vault user and directories
useradd --system --home /etc/vault.d --shell /bin/false vault || true
mkdir -p /etc/vault.d
mkdir -p /opt/vault/data
chown -R vault:vault /etc/vault.d /opt/vault/data
chmod 700 /opt/vault/data

# Vault configuration
cat <<EOF >/etc/vault.d/vault.hcl
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = 1
}

storage "file" {
  path = "/opt/vault/data"
}

seal "awskms" {
  region = "${REGION}"
  kms_key_id = "${KMS_KEY_ID}"
}

ui = true
EOF

chown vault:vault /etc/vault.d/vault.hcl
chmod 640 /etc/vault.d/vault.hcl

# Create systemd service
cat <<EOF >/etc/systemd/system/vault.service
[Unit]
Description=Vault service
Requires=network-online.target
After=network-online.target

[Service]
User=vault
Group=vault
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP \$MAINPID
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Vault
systemctl daemon-reload
systemctl enable vault
systemctl start vault

# Wait for Vault to be ready
sleep 10

# Initialize Vault (if uninitialized)
export VAULT_ADDR='http://127.0.0.1:8200'
if ! vault status | grep -q "Initialized"; then
  vault operator init -key-shares=1 -key-threshold=1 -format=json > /root/vault_init.json
  VAULT_ROOT_TOKEN=$(jq -r '.root_token' /root/vault_init.json)
else
  VAULT_ROOT_TOKEN=$(vault status -format=json | jq -r '.root_token // empty')
fi

export VAULT_TOKEN=$VAULT_ROOT_TOKEN

# Enable KV secrets engine
vault secrets enable -path=secret kv || true

# Store database credentials in Vault
vault kv put secret/db username="Chijioke" password="Chijioke014" || true

echo "Vault installation complete and running on port 8200"
echo "Database credentials stored at secret/db"


# #!/bin/bash
# set -e
# apt install -y unzip jq
# # Define Vault version
# VAULT_VERSION="1.18.3"
# # Download Vault binary
# wget https://releases.hashicorp.com/vault/"${VAULT_VERSION}"/vault_"${VAULT_VERSION}"_linux_amd64.zip
# # Unzip the Vault binary
# unzip vault_"${VAULT_VERSION}"_linux_amd64.zip
# # Move the binary to /usr/local/bin
# sudo mv vault /usr/local/bin/
# # Set ownership and permissions
# sudo chown root:root /usr/local/bin/vault
# sudo chmod 0755 /usr/local/bin/vault
# # Create Vault user and directories
# sudo useradd --system --home /etc/vault.d --shell /bin/false vault
# sudo mkdir --parents /etc/vault.d
# sudo mkdir --parents /var/lib/vault
# sudo chown --recursive vault:vault /etc/vault.d /var/lib/vault
# # Create Vault configuration file
# cat <<EOF | sudo tee /etc/vault.d/vault.hcl
# storage "file" {
#     path = "/var/lib/vault"
# }
# listener "tcp" {
#     address     = "0.0.0.0:8200"
#     tls_disable = 1
# }
# seal "awskms" {
#     region = "${region}"
#     kms_key_id = "${key}"
# }
# ui = true
# EOF
# # Set permissions for the configuration file
# sudo chown vault:vault /etc/vault.d/vault.hcl
# sudo chmod 640 /etc/vault.d/vault.hcl
# # Create systemd service file for Vault
# cat <<EOF | sudo tee /etc/systemd/system/vault.service
# [Unit]
# Description=HashiCorp Vault - A tool for managing secrets
# Documentation=https://www.vaultproject.io/docs/
# Requires=network-online.target
# After=network-online.target
# [Service]
# User=vault
# Group=vault
# ProtectSystem=full
# ProtectHome=read-only
# PrivateTmp=yes
# PrivateDevices=yes
# SecureBits=keep-caps
# Capabilities=CAP_IPC_LOCK+ep
# CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
# NoNewPrivileges=yes
# ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
# ExecReload=/bin/kill --signal HUP \$MAINPID
# KillMode=process
# KillSignal=SIGINT
# Restart=on-failure
# RestartSec=5
# StartLimitInterval=60
# StartLimitBurst=3
# LimitNOFILE=65536
# LimitMEMLOCK=infinity
# [Install]
# WantedBy=multi-user.target
# EOF
# # Reload systemd to recognize the new service
# sudo systemctl daemon-reload
# # Wait for Vault to start
# sleep 5
# # create a variable for the vault URL
# export VAULT_ADDR='http://localhost:8200'
# cat <<EOT > /etc/profile.d/vault.sh
# export VAULT_ADDR='http://localhost:8200'
# export VAULT_SKIP_VERIFY=true
# EOT
# # Enable and start the Vault service
# sudo systemctl enable vault
# sudo systemctl start vault
# sleep 20
# # Initialize the vault server
# touch /home/ubuntu/vault_init.log
# vault operator init > /home/ubuntu/vault_init.log
# grep -o 'hvs\.[A-Za-z0-9]\{24\}' /home/ubuntu/vault_init.log > /home/ubuntu/token.txt
# TOKEN=$(</home/ubuntu/token.txt)
# # Login to Vault
# vault login $TOKEN
# # create secret engine and store secrets for the application database
# vault secrets enable -path=secret/ kv #directory to store secrets on the vault server
# vault kv put secret/database username=petclinic password=petclinic
# # Set hostname to Vault
# sudo hostnamectl set-hostname Vault