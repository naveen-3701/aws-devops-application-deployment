#!/bin/bash

# EC2 Instance Setup Script
# This script helps set up the EC2 instance for deployment

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [EC2_PUBLIC_IP] [KEY_FILE_PATH]"
    echo ""
    echo "Arguments:"
    echo "  EC2_PUBLIC_IP    Public IP address of your EC2 instance"
    echo "  KEY_FILE_PATH    Path to your .pem key file"
    echo ""
    echo "Example:"
    echo "  $0 3.15.123.45 /path/to/devops-app-key.pem"
}

# Function to test SSH connection
test_ssh_connection() {
    local ec2_ip=$1
    local key_file=$2
    
    print_status "Testing SSH connection to EC2 instance..."
    
    if ssh -i "$key_file" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "ec2-user@$ec2_ip" "echo 'SSH connection successful'" > /dev/null 2>&1; then
        print_success "SSH connection successful!"
        return 0
    else
        print_error "SSH connection failed!"
        return 1
    fi
}

# Function to install Docker on EC2
install_docker_on_ec2() {
    local ec2_ip=$1
    local key_file=$2
    
    print_status "Installing Docker on EC2 instance..."
    
    ssh -i "$key_file" -o StrictHostKeyChecking=no "ec2-user@$ec2_ip" "
        sudo yum update -y
        sudo yum install -y docker
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -a -G docker ec2-user
        sudo yum install -y curl wget git
        echo 'Docker installation completed!'
    "
    
    print_success "Docker installed successfully on EC2!"
}

# Function to test Docker installation
test_docker_installation() {
    local ec2_ip=$1
    local key_file=$2
    
    print_status "Testing Docker installation..."
    
    ssh -i "$key_file" -o StrictHostKeyChecking=no "ec2-user@$ec2_ip" "
        docker --version
        docker run hello-world
    "
    
    print_success "Docker test completed successfully!"
}

# Function to update Jenkins credentials
update_jenkins_credentials() {
    local ec2_ip=$1
    local key_file=$2
    
    print_status "Updating Jenkins credentials..."
    
    # Create a script to update Jenkins credentials
    cat > update_jenkins_creds.sh << EOF
#!/bin/bash

# Update Jenkins credentials
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin123"

# Get Jenkins crumb
CRUMB=\$(curl -s -u "\$JENKINS_USER:\$JENKINS_PASSWORD" "\$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,%22:%22,//crumb)")

# Update AWS EC2 Host credential
curl -s -X POST -u "\$JENKINS_USER:\$JENKINS_PASSWORD" \\
    -H "\$CRUMB" \\
    -H "Content-Type: application/x-www-form-urlencoded" \\
    -d "json={\"\":\"4\",\"credentials\":{\"scope\":\"GLOBAL\",\"id\":\"aws-ec2-host\",\"secret\":\"$ec2_ip\",\"description\":\"AWS EC2 Host IP\",\"stapler-class\":\"com.cloudbees.plugins.credentials.impl.StringCredentialsImpl\",\"\$class\":\"com.cloudbees.plugins.credentials.impl.StringCredentialsImpl\"}}" \\
    "\$JENKINS_URL/credentials/store/system/domain/_/createCredentials" > /dev/null

echo "Jenkins credentials updated successfully!"
EOF
    
    chmod +x update_jenkins_creds.sh
    
    print_status "Run this command to update Jenkins credentials:"
    print_status "./update_jenkins_creds.sh"
    print_status ""
    print_status "Or manually update in Jenkins:"
    print_status "1. Go to: http://localhost:8080"
    print_status "2. Manage Jenkins → Manage Credentials"
    print_status "3. Update 'aws-ec2-host' with: $ec2_ip"
    print_status "4. Update 'aws-ec2-key' with your .pem key file"
}

# Function to test deployment
test_deployment() {
    local ec2_ip=$1
    local key_file=$2
    
    print_status "Testing deployment..."
    
    # Test the deployment script
    if [ -f "./deploy.sh" ]; then
        print_status "Running deployment test..."
        ./deploy.sh dev "$ec2_ip" "$key_file"
        
        # Wait a bit for deployment to complete
        sleep 30
        
        # Test the application
        print_status "Testing application..."
        if curl -f "http://$ec2_ip" > /dev/null 2>&1; then
            print_success "Application is accessible!"
        else
            print_warning "Application might not be ready yet. Check EC2 instance logs."
        fi
        
        if curl -f "http://$ec2_ip/health" > /dev/null 2>&1; then
            print_success "Health check passed!"
        else
            print_warning "Health check failed. Check application logs."
        fi
    else
        print_error "deploy.sh not found!"
        return 1
    fi
}

# Main execution
main() {
    local ec2_ip=$1
    local key_file=$2
    
    if [ -z "$ec2_ip" ] || [ -z "$key_file" ]; then
        print_error "Missing required arguments!"
        show_usage
        exit 1
    fi
    
    if [ ! -f "$key_file" ]; then
        print_error "Key file not found: $key_file"
        exit 1
    fi
    
    print_status "Setting up EC2 instance: $ec2_ip"
    print_status "Using key file: $key_file"
    echo ""
    
    # Test SSH connection
    if ! test_ssh_connection "$ec2_ip" "$key_file"; then
        print_error "Cannot connect to EC2 instance. Please check:"
        print_status "1. Instance is running"
        print_status "2. Security group allows SSH from your IP"
        print_status "3. Key file path is correct"
        print_status "4. Key file permissions: chmod 400 $key_file"
        exit 1
    fi
    
    # Install Docker
    install_docker_on_ec2 "$ec2_ip" "$key_file"
    
    # Test Docker installation
    test_docker_installation "$ec2_ip" "$key_file"
    
    # Update Jenkins credentials
    update_jenkins_credentials "$ec2_ip" "$key_file"
    
    # Test deployment
    test_deployment "$ec2_ip" "$key_file"
    
    print_success "EC2 instance setup completed successfully!"
    print_status "Your EC2 instance is ready for deployment!"
    print_status "Application URL: http://$ec2_ip"
    print_status "Health Check URL: http://$ec2_ip/health"
}

# Check if script is run with arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

# Run main function
main "$@"
