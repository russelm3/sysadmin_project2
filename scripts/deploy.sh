#!/bin/bash
set -e

echo "=== Configuring AWS credentials ==="
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-1}

echo "=== Cleaning up any pre-existing key pair ==="
aws ec2 delete-key-pair --key-name minecraft-key 2>/dev/null || true

echo "=== Running Terraform ==="
cd terraform
terraform init
terraform apply -auto-approve

PUBLIC_IP=$(terraform output -raw public_ip)
echo "Instance public IP: $PUBLIC_IP"

echo "=== Generating Ansible inventory ==="
cd ../ansible
cat > inventory.ini <<EOF
[minecraft]
$PUBLIC_IP ansible_user=ubuntu ansible_ssh_private_key_file=/home/russelm3/.ssh/minecraft_rsa ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo "=== Waiting for instance to pass status checks ==="
cd ../terraform
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=ip-address,Values=$PUBLIC_IP" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)
aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID
echo "Instance ready."
sleep 15

echo "=== Running Ansible ==="
cd ../ansible
ansible-playbook -i inventory.ini playbook.yml

echo "=== Verifying with nmap ==="
nmap -sV -Pn -p T:25565 $PUBLIC_IP

echo "=== Done! Connect to your Minecraft server at $PUBLIC_IP:25565 ==="