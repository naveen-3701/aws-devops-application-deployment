#!/bin/bash

# AWS EC2 Instance Launch Script
# This script provides step-by-step instructions for launching EC2 instance

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "AWS EC2 Instance Launch Guide"
echo ""
print_status "=== STEP 1: LAUNCH EC2 INSTANCE ==="
echo ""
print_status "1. Go to AWS Console: https://console.aws.amazon.com/ec2/"
print_status "2. Click 'Launch Instance'"
print_status "3. Configure the instance:"
echo ""
print_status "   Instance Details:"
print_status "   - Name: devops-application-server"
print_status "   - AMI: Amazon Linux 2 (ami-0c02fb55956c7d316)"
print_status "   - Instance Type: t2.micro (Free Tier)"
print_status "   - Key Pair: Create new key pair"
print_status "     * Key pair name: devops-app-key"
print_status "     * Key pair type: RSA"
print_status "     * Private key file format: .pem"
print_status "     * Click 'Create key pair'"
echo ""
print_status "   Network Settings:"
print_status "   - VPC: Default VPC"
print_status "   - Subnet: No preference (default subnet)"
print_status "   - Auto-assign public IP: Enable"
print_status "   - Security Group: Create security group"
print_status "     * Security group name: devops-app-sg"
print_status "     * Description: Security group for DevOps application"
print_status "     * Inbound rules:"
print_status "       - Type: HTTP, Protocol: TCP, Port: 80, Source: 0.0.0.0/0"
print_status "       - Type: SSH, Protocol: TCP, Port: 22, Source: My IP"
print_status "     * Outbound rules: All traffic (default)"
echo ""
print_status "   Storage:"
print_status "   - Volume type: gp3"
print_status "   - Size: 8 GiB (default)"
print_status "   - Encryption: Not encrypted (default)"
echo ""
print_status "4. Click 'Launch Instance'"
print_status "5. Click 'View all instances'"
echo ""
print_status "=== STEP 2: NOTE DOWN DETAILS ==="
echo ""
print_status "After launching, note down:"
print_status "1. Instance ID (e.g., i-1234567890abcdef0)"
print_status "2. Public IPv4 address (e.g., 3.15.123.45)"
print_status "3. Download the .pem key file to your local machine"
print_status "4. Save the key file in a secure location"
echo ""
print_status "=== STEP 3: WAIT FOR INSTANCE TO BE READY ==="
echo ""
print_status "Wait for the instance state to be 'Running' and status checks to be '2/2 checks passed'"
print_status "This usually takes 2-3 minutes"
echo ""
print_status "=== STEP 4: TEST CONNECTION ==="
echo ""
print_status "Once the instance is ready, test the connection:"
print_status "ssh -i devops-app-key.pem ec2-user@YOUR_PUBLIC_IP"
echo ""
print_status "If successful, you should see the Amazon Linux prompt"
echo ""
print_status "=== STEP 5: INSTALL DOCKER ON EC2 ==="
echo ""
print_status "After connecting to EC2, run these commands:"
print_status "sudo yum update -y"
print_status "sudo yum install -y docker"
print_status "sudo systemctl start docker"
print_status "sudo systemctl enable docker"
print_status "sudo usermod -a -G docker ec2-user"
print_status "sudo yum install -y curl wget git"
print_status "exit"
echo ""
print_status "Then reconnect to apply the docker group changes:"
print_status "ssh -i devops-app-key.pem ec2-user@YOUR_PUBLIC_IP"
print_status "docker --version"
print_status "docker run hello-world"
echo ""
print_status "=== STEP 6: UPDATE JENKINS CREDENTIALS ==="
echo ""
print_status "After getting the EC2 details, update Jenkins credentials:"
print_status "1. Go to Jenkins: http://localhost:8080"
print_status "2. Manage Jenkins → Manage Credentials"
print_status "3. Update 'aws-ec2-host' with your EC2 public IP"
print_status "4. Update 'aws-ec2-key' with your .pem key file"
echo ""
print_status "=== STEP 7: TEST DEPLOYMENT ==="
echo ""
print_status "Test the deployment:"
print_status "./deploy.sh dev YOUR_EC2_IP /path/to/devops-app-key.pem"
echo ""
print_status "Then verify the application:"
print_status "curl http://YOUR_EC2_IP"
print_status "curl http://YOUR_EC2_IP/health"
echo ""
print_success "EC2 instance launch guide completed!"
print_status "Follow these steps to launch your EC2 instance and set up the deployment environment."
