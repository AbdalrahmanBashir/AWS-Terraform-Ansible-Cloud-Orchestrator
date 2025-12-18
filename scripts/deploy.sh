#!/bin/bash

# Move to terraform directory and apply changes
echo "Starting Infrastructure Deployment..."
cd ../terraform
terraform apply -auto-approve

# Get the IP address from Terraform Output
# We use -raw to get just the numbers without quotes
INSTANCE_IP=$(terraform output -raw instance_public_ip)

if [ -z "$INSTANCE_IP" ]; then
    echo " Error: Could not retrieve IP from Terraform."
    exit 1
fi

echo "Infrastructure is live at: $INSTANCE_IP"

echo "------------------------------------------------------------"
echo "ACTION REQUIRED: Update Cloudflare A record"
echo "Point the subdomain to: $INSTANCE_IP"
echo "------------------------------------------------------------"
read -p "Press [Enter] once Cloudflare is updated to continue..."

# Update the Ansible hosts.ini file
echo "Updating Ansible Inventory..."
cat <<EOF > ../ansible/hosts.ini
[webservers]
$INSTANCE_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa_terraform
EOF

# Move to ansible directory and run the playbook
echo "Starting Configuration Management..."
cd ../ansible

# Wait a few seconds for SSH to be ready on the new instance
echo "Waiting for SSH to wake up..."
sleep 15

ansible-playbook -i hosts.ini setup.yml