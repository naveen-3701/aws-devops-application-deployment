#!/bin/bash

# DevOps Application Deployment Script
# This script deploys the application to AWS EC2 instance

set -e  # Exit on any error

# Configuration
DOCKER_HUB_USERNAME="naveen3701"
DEV_REPO="naveen-3701-devops-app-dev"
PROD_REPO="naveen-3701-devops-app-prod"
DEV_TAG="dev"
PROD_TAG="prod"
CONTAINER_NAME="devops-application"
HOST_PORT="80"
CONTAINER_PORT="80"

# AWS Configuration (will be set via environment variables or parameters)
AWS_EC2_HOST=""
AWS_EC2_USER="ec2-user"
AWS_EC2_KEY=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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
    echo "Usage: $0 [dev|prod] [EC2_HOST] [EC2_KEY_PATH]"
    echo ""
    echo "Arguments:"
    echo "  dev|prod     - Environment to deploy (dev or prod)"
    echo "  EC2_HOST     - AWS EC2 instance public IP or hostname"
    echo "  EC2_KEY_PATH - Path to AWS EC2 private key file"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_EC2_HOST - AWS EC2 instance public IP or hostname"
    echo "  AWS_EC2_KEY  - Path to AWS EC2 private key file"
    echo ""
    echo "Examples:"
    echo "  $0 dev 54.123.45.67 ~/.ssh/my-key.pem"
    echo "  AWS_EC2_HOST=54.123.45.67 AWS_EC2_KEY=~/.ssh/my-key.pem $0 prod"
}

# Function to validate parameters
validate_params() {
    local environment=$1
    local host=$2
    local key=$3
    
    if [ -z "$environment" ]; then
        print_error "Environment parameter is required (dev or prod)"
        show_usage
        exit 1
    fi
    
    if [ "$environment" != "dev" ] && [ "$environment" != "prod" ]; then
        print_error "Environment must be 'dev' or 'prod'"
        show_usage
        exit 1
    fi
    
    # Use parameters or environment variables
    if [ -n "$host" ]; then
        AWS_EC2_HOST="$host"
    elif [ -z "$AWS_EC2_HOST" ]; then
        print_error "AWS EC2 host is required"
        show_usage
        exit 1
    fi
    
    if [ -n "$key" ]; then
        AWS_EC2_KEY="$key"
    elif [ -z "$AWS_EC2_KEY" ]; then
        print_error "AWS EC2 key path is required"
        show_usage
        exit 1
    fi
    
    # Expand tilde in key path
    AWS_EC2_KEY="${AWS_EC2_KEY/#\~/$HOME}"
    
    if [ ! -f "$AWS_EC2_KEY" ]; then
        print_error "AWS EC2 key file not found: $AWS_EC2_KEY"
        exit 1
    fi
}

# Function to test SSH connection
test_ssh_connection() {
    print_status "Testing SSH connection to $AWS_EC2_HOST..."
    
    if ssh -i "$AWS_EC2_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$AWS_EC2_USER@$AWS_EC2_HOST" "echo 'SSH connection successful'" > /dev/null 2>&1; then
        print_success "SSH connection successful"
    else
        print_error "Failed to connect to EC2 instance via SSH"
        exit 1
    fi
}

# Function to install Docker on EC2 if not present
install_docker_on_ec2() {
    print_status "Checking Docker installation on EC2 instance..."
    
    ssh -i "$AWS_EC2_KEY" -o StrictHostKeyChecking=no "$AWS_EC2_USER@$AWS_EC2_HOST" '
        if ! command -v docker &> /dev/null; then
            echo "Installing Docker..."
            sudo yum update -y
            sudo yum install -y docker
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -a -G docker ec2-user
            echo "Docker installed successfully"
        else
            echo "Docker is already installed"
        fi
    '
}

# Function to deploy application
deploy_application() {
    local environment=$1
    local repo_name=""
    if [ "$environment" = "dev" ]; then
        repo_name="${DEV_REPO}"
    else
        repo_name="${PROD_REPO}"
    fi
    local image_tag="${DOCKER_HUB_USERNAME}/${repo_name}:${environment}"
    
    print_status "Deploying application for $environment environment..."
    print_status "Using image: $image_tag"
    
    ssh -i "$AWS_EC2_KEY" -o StrictHostKeyChecking=no "$AWS_EC2_USER@$AWS_EC2_HOST" "
        # Stop and remove existing container if it exists
        if docker ps -a --format 'table {{.Names}}' | grep -q '^${CONTAINER_NAME}$'; then
            echo 'Stopping existing container...'
            docker stop ${CONTAINER_NAME} || true
            docker rm ${CONTAINER_NAME} || true
        fi
        
        # Pull the latest image
        echo 'Pulling latest image...'
        docker pull ${image_tag}
        
        # Run the new container
        echo 'Starting new container...'
        docker run -d \
            --name ${CONTAINER_NAME} \
            --restart unless-stopped \
            -p ${HOST_PORT}:${CONTAINER_PORT} \
            ${image_tag}
        
        # Wait a moment for container to start
        sleep 5
        
        # Check if container is running
        if docker ps --format 'table {{.Names}}' | grep -q '^${CONTAINER_NAME}$'; then
            echo 'Container started successfully'
            docker ps --filter name=${CONTAINER_NAME}
        else
            echo 'Failed to start container'
            docker logs ${CONTAINER_NAME}
            exit 1
        fi
    "
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Wait for application to be ready
    sleep 10
    
    # Test HTTP endpoint
    if curl -f -s "http://$AWS_EC2_HOST/health" > /dev/null; then
        print_success "Application health check passed"
    else
        print_warning "Application health check failed, but deployment may still be successful"
    fi
    
    # Test main endpoint
    if curl -f -s "http://$AWS_EC2_HOST" > /dev/null; then
        print_success "Application is accessible at http://$AWS_EC2_HOST"
    else
        print_warning "Application may not be fully ready yet"
    fi
}

# Function to show deployment summary
show_summary() {
    local environment=$1
    
    print_success "Deployment completed successfully!"
    echo ""
    print_status "Deployment Summary:"
    print_status "  Environment: $environment"
    print_status "  EC2 Host: $AWS_EC2_HOST"
    print_status "  Application URL: http://$AWS_EC2_HOST"
    print_status "  Health Check URL: http://$AWS_EC2_HOST/health"
    print_status "  Container Name: $CONTAINER_NAME"
    print_status "  Image: ${DOCKER_HUB_USERNAME}/${repo_name}:${environment}"
    echo ""
    print_status "Useful commands:"
    print_status "  SSH to server: ssh -i $AWS_EC2_KEY $AWS_EC2_USER@$AWS_EC2_HOST"
    print_status "  View logs: ssh -i $AWS_EC2_KEY $AWS_EC2_USER@$AWS_EC2_HOST 'docker logs $CONTAINER_NAME'"
    print_status "  Restart app: ssh -i $AWS_EC2_KEY $AWS_EC2_USER@$AWS_EC2_HOST 'docker restart $CONTAINER_NAME'"
}

# Main execution
main() {
    local environment=$1
    local host=$2
    local key=$3
    
    print_status "Starting DevOps Application Deployment"
    
    # Validate parameters
    validate_params "$environment" "$host" "$key"
    
    print_status "Deployment Configuration:"
    print_status "  Environment: $environment"
    print_status "  EC2 Host: $AWS_EC2_HOST"
    print_status "  EC2 Key: $AWS_EC2_KEY"
    print_status "  Image: ${DOCKER_HUB_USERNAME}/${repo_name}:$environment"
    
    # Test SSH connection
    test_ssh_connection
    
    # Install Docker if needed
    install_docker_on_ec2
    
    # Deploy application
    deploy_application "$environment"
    
    # Verify deployment
    verify_deployment
    
    # Show summary
    show_summary "$environment"
}

# Check if help is requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
    exit 0
fi

# Run main function
main "$@"
