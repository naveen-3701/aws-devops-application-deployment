#!/bin/bash

# Complete DevOps Pipeline Launch Script
# This script launches everything: EC2, Jenkins, and sets up the complete pipeline

set -e

# AWS Configuration
# Set these environment variables before running the script:
# export AWS_ACCESS_KEY_ID="your-access-key"
# export AWS_SECRET_ACCESS_KEY="your-secret-key"
# export AWS_DEFAULT_REGION="us-east-1"

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "Error: AWS credentials not set. Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables."
    exit 1
fi

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

# Function to check AWS CLI
check_aws_cli() {
    print_status "Checking AWS CLI..."
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Installing..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew install awscli
            else
                print_error "Please install AWS CLI manually: https://aws.amazon.com/cli/"
                exit 1
            fi
        else
            # Linux
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
        fi
    fi
    print_success "AWS CLI is ready!"
}

# Function to configure AWS credentials
configure_aws() {
    print_status "Configuring AWS credentials..."
    aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
    aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
    aws configure set default.region "${AWS_DEFAULT_REGION:-us-east-1}"
    print_success "AWS credentials configured!"
}

# Function to create security group
create_security_group() {
    print_status "Creating security group..."
    
    # Check if security group already exists
    if aws ec2 describe-security-groups --group-names "devops-app-sg" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null | grep -q "sg-"; then
        SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --group-names "devops-app-sg" --query 'SecurityGroups[0].GroupId' --output text)
        print_warning "Security group already exists: $SECURITY_GROUP_ID"
    else
        # Create security group
        SECURITY_GROUP_ID=$(aws ec2 create-security-group \
            --group-name "devops-app-sg" \
            --description "Security group for DevOps application" \
            --query 'GroupId' \
            --output text)
        print_success "Security group created: $SECURITY_GROUP_ID"
    fi
    
    # Get current public IP
    CURRENT_IP=$(curl -s https://checkip.amazonaws.com)
    print_status "Current public IP: $CURRENT_IP"
    
    # Add HTTP rule
    print_status "Adding HTTP rule..."
    aws ec2 authorize-security-group-ingress \
        --group-id "$SECURITY_GROUP_ID" \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0 2>/dev/null || print_warning "HTTP rule already exists"
    
    # Add SSH rule
    print_status "Adding SSH rule..."
    aws ec2 authorize-security-group-ingress \
        --group-id "$SECURITY_GROUP_ID" \
        --protocol tcp \
        --port 22 \
        --cidr "$CURRENT_IP/32" 2>/dev/null || print_warning "SSH rule already exists"
    
    print_success "Security group configured!"
}

# Function to create key pair
create_key_pair() {
    print_status "Creating key pair..."
    
    # Check if key pair already exists
    if aws ec2 describe-key-pairs --key-names "devops-app-key" --query 'KeyPairs[0].KeyName' --output text 2>/dev/null | grep -q "devops-app-key"; then
        print_warning "Key pair already exists"
    else
        # Create key pair
        aws ec2 create-key-pair \
            --key-name "devops-app-key" \
            --query 'KeyMaterial' \
            --output text > devops-app-key.pem
        chmod 400 devops-app-key.pem
        print_success "Key pair created: devops-app-key.pem"
    fi
}

# Function to launch EC2 instance
launch_ec2_instance() {
    print_status "Launching EC2 instance..."
    
    # Get the latest Amazon Linux 2 AMI ID
    AMI_ID=$(aws ec2 describe-images \
        --owners amazon \
        --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
        --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
        --output text)
    
    print_status "Using AMI: $AMI_ID"
    
    # Launch instance
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --count 1 \
        --instance-type t2.micro \
        --key-name "devops-app-key" \
        --security-group-ids "$SECURITY_GROUP_ID" \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=devops-application-server}]' \
        --query 'Instances[0].InstanceId' \
        --output text)
    
    print_success "EC2 instance launched: $INSTANCE_ID"
    
    # Wait for instance to be running
    print_status "Waiting for instance to be running..."
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
    
    # Get public IP
    PUBLIC_IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
    
    print_success "Instance is running! Public IP: $PUBLIC_IP"
    
    # Save instance details
    echo "INSTANCE_ID=$INSTANCE_ID" > instance-details.txt
    echo "PUBLIC_IP=$PUBLIC_IP" >> instance-details.txt
    echo "SECURITY_GROUP_ID=$SECURITY_GROUP_ID" >> instance-details.txt
}

# Function to setup EC2 instance
setup_ec2_instance() {
    print_status "Setting up EC2 instance..."
    
    # Wait a bit more for SSH to be ready
    print_status "Waiting for SSH to be ready..."
    sleep 60
    
    # Test SSH connection
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if ssh -i devops-app-key.pem -o StrictHostKeyChecking=no -o ConnectTimeout=10 "ec2-user@$PUBLIC_IP" "echo 'SSH ready'" > /dev/null 2>&1; then
            print_success "SSH connection successful!"
            break
        fi
        print_status "Attempt $attempt/$max_attempts - SSH not ready yet..."
        sleep 30
        ((attempt++))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_error "SSH connection failed after $max_attempts attempts"
        return 1
    fi
    
    # Install Docker and required tools
    print_status "Installing Docker and tools on EC2..."
    ssh -i devops-app-key.pem -o StrictHostKeyChecking=no "ec2-user@$PUBLIC_IP" "
        sudo yum update -y
        sudo yum install -y docker
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -a -G docker ec2-user
        sudo yum install -y curl wget git
        echo 'Installation completed!'
    "
    
    print_success "EC2 instance setup completed!"
}

# Function to update Jenkins credentials
update_jenkins_credentials() {
    print_status "Updating Jenkins credentials..."
    
    # Create script to update Jenkins credentials
    cat > update-jenkins-creds.sh << EOF
#!/bin/bash

JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin123"

# Get Jenkins crumb
CRUMB=\$(curl -s -u "\$JENKINS_USER:\$JENKINS_PASSWORD" "\$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,%22:%22,//crumb)")

# Update AWS EC2 Host credential
curl -s -X POST -u "\$JENKINS_USER:\$JENKINS_PASSWORD" \\
    -H "\$CRUMB" \\
    -H "Content-Type: application/x-www-form-urlencoded" \\
    -d "json={\"\":\"4\",\"credentials\":{\"scope\":\"GLOBAL\",\"id\":\"aws-ec2-host\",\"secret\":\"$PUBLIC_IP\",\"description\":\"AWS EC2 Host IP\",\"stapler-class\":\"com.cloudbees.plugins.credentials.impl.StringCredentialsImpl\",\"\$class\":\"com.cloudbees.plugins.credentials.impl.StringCredentialsImpl\"}}" \\
    "\$JENKINS_URL/credentials/store/system/domain/_/createCredentials" > /dev/null

# Update Docker Hub credentials
curl -s -X POST -u "\$JENKINS_USER:\$JENKINS_PASSWORD" \\
    -H "\$CRUMB" \\
    -H "Content-Type: application/x-www-form-urlencoded" \\
    -d "json={\"\":\"4\",\"credentials\":{\"scope\":\"GLOBAL\",\"id\":\"docker-hub-credentials\",\"username\":\"naveen3701\",\"password\":\"your-docker-password\",\"description\":\"Docker Hub credentials\",\"stapler-class\":\"com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl\",\"\$class\":\"com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl\"}}" \\
    "\$JENKINS_URL/credentials/store/system/domain/_/createCredentials" > /dev/null

echo "Jenkins credentials updated!"
EOF
    
    chmod +x update-jenkins-creds.sh
    print_success "Jenkins credentials update script created!"
}

# Function to test deployment
test_deployment() {
    print_status "Testing deployment..."
    
    # Test the deployment script
    if [ -f "./deploy.sh" ]; then
        print_status "Running deployment test..."
        ./deploy.sh dev "$PUBLIC_IP" "devops-app-key.pem"
        
        # Wait for deployment to complete
        print_status "Waiting for deployment to complete..."
        sleep 60
        
        # Test the application
        print_status "Testing application..."
        if curl -f "http://$PUBLIC_IP" > /dev/null 2>&1; then
            print_success "Application is accessible!"
        else
            print_warning "Application might not be ready yet. Check EC2 instance logs."
        fi
        
        if curl -f "http://$PUBLIC_IP/health" > /dev/null 2>&1; then
            print_success "Health check passed!"
        else
            print_warning "Health check failed. Check application logs."
        fi
    else
        print_error "deploy.sh not found!"
        return 1
    fi
}

# Function to setup monitoring
setup_monitoring() {
    print_status "Setting up monitoring..."
    
    # Create monitoring directory
    mkdir -p monitoring
    
    # Create Prometheus configuration
    cat > monitoring/prometheus.yml << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'devops-app'
    static_configs:
      - targets: ['$PUBLIC_IP:80']
    metrics_path: '/metrics'
    scrape_interval: 30s
EOF
    
    # Create Grafana configuration
    cat > monitoring/docker-compose.yml << EOF
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    volumes:
      - grafana-storage:/var/lib/grafana

volumes:
  grafana-storage:
EOF
    
    print_success "Monitoring setup completed!"
}

# Function to display summary
display_summary() {
    print_success "🎉 DevOps Pipeline Launch Completed Successfully!"
    echo ""
    print_status "=== DEPLOYMENT SUMMARY ==="
    print_status "EC2 Instance ID: $INSTANCE_ID"
    print_status "EC2 Public IP: $PUBLIC_IP"
    print_status "Security Group ID: $SECURITY_GROUP_ID"
    print_status "Key Pair: devops-app-key.pem"
    echo ""
    print_status "=== ACCESS INFORMATION ==="
    print_status "Application URL: http://$PUBLIC_IP"
    print_status "Health Check URL: http://$PUBLIC_IP/health"
    print_status "Jenkins URL: http://localhost:8080"
    print_status "Jenkins Username: admin"
    print_status "Jenkins Password: admin123"
    echo ""
    print_status "=== MONITORING ==="
    print_status "Prometheus: http://localhost:9090"
    print_status "Grafana: http://localhost:3000 (admin/admin123)"
    echo ""
    print_status "=== NEXT STEPS ==="
    print_status "1. Update Jenkins credentials: ./update-jenkins-creds.sh"
    print_status "2. Start monitoring: cd monitoring && docker-compose up -d"
    print_status "3. Test the pipeline by pushing to dev branch"
    print_status "4. Monitor deployments in Jenkins"
    echo ""
    print_success "Everything is ready! 🚀"
}

# Main execution
main() {
    print_status "🚀 Starting Complete DevOps Pipeline Launch..."
    echo ""
    
    # Check AWS CLI
    check_aws_cli
    
    # Configure AWS
    configure_aws
    
    # Create security group
    create_security_group
    
    # Create key pair
    create_key_pair
    
    # Launch EC2 instance
    launch_ec2_instance
    
    # Setup EC2 instance
    setup_ec2_instance
    
    # Update Jenkins credentials
    update_jenkins_credentials
    
    # Test deployment
    test_deployment
    
    # Setup monitoring
    setup_monitoring
    
    # Display summary
    display_summary
}

# Run main function
main "$@"