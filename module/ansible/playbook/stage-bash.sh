#!/bin/bash
set -xe

# --- Variables ---
AWSCLI_PATH='/usr/local/bin/aws'
INVENTORY_FILE='/etc/ansible/stage_hosts'
IPS_FILE='/etc/ansible/stage.lists'
ASG_NAME='personal-stage-asg'
SSH_KEY_PATH='/home/ec2-user/.ssh/id_rsa'
WAIT_TIME=20

# --- Functions ---

# Fetch private IPs of instances in the ASG
find_ips() {
    $AWSCLI_PATH ec2 describe-instances \
        --filters "Name=tag:aws:autoscaling:groupName,Values=$ASG_NAME" \
        --query 'Reservations[*].Instances[*].PrivateIpAddress' \
        --output text > "$IPS_FILE"
}

# Update Ansible inventory file
update_inventory() {
    echo "[webservers]" > "$INVENTORY_FILE"
    while IFS= read -r instance; do
        ssh-keyscan -H "$instance" >> /home/ec2-user/.ssh/known_hosts
        echo "$instance ansible_user=ec2-user" >> "$INVENTORY_FILE"
    done < "$IPS_FILE"
    echo "Inventory updated successfully."
}

# Wait for a defined number of seconds
wait_for_seconds() {
    echo "Waiting for $WAIT_TIME seconds..."
    sleep "$WAIT_TIME"
}

# Check Docker container on each instance, start if not running
check_docker_container() {
    while IFS= read -r instance; do
        ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no ec2-user@"$instance" \
            "docker ps | grep -q appContainer"
        if [ $? -ne 0 ]; then
            echo "Container not running on $instance. Starting container..."
            ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no ec2-user@"$instance" \
                "bash /home/ec2-user/scripts/script.sh"
        else
            echo "Container is running on $instance."
        fi
    done < "$IPS_FILE"
}

# --- Main ---
main() {
    find_ips
    update_inventory
    wait_for_seconds
    check_docker_container
}

# Execute main
main
