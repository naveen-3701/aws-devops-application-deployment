#!/bin/bash

# Simple Jenkins Setup Script
# This script automates the basic Jenkins setup

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

# Configuration
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin123"

# Function to check if Jenkins is ready
check_jenkins_ready() {
    print_status "Checking if Jenkins is ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$JENKINS_URL/login" > /dev/null 2>&1; then
            print_success "Jenkins is ready!"
            return 0
        fi
        print_status "Attempt $attempt/$max_attempts - Jenkins not ready yet, waiting..."
        sleep 10
        ((attempt++))
    done
    
    print_error "Jenkins is not ready after $max_attempts attempts"
    return 1
}

# Function to get Jenkins crumb for CSRF protection
get_jenkins_crumb() {
    local crumb=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,%22:%22,//crumb)")
    echo "$crumb"
}

# Function to install Jenkins plugins
install_jenkins_plugins() {
    print_status "Installing required Jenkins plugins..."
    
    local plugins=(
        "git"
        "github"
        "docker-workflow"
        "credentials-binding"
        "ssh-agent"
        "build-timeout"
        "timestamper"
        "ws-cleanup"
        "workflow-aggregator"
        "pipeline-stage-view"
        "github-branch-source"
        "blueocean"
    )
    
    local crumb=$(get_jenkins_crumb)
    
    for plugin in "${plugins[@]}"; do
        print_status "Installing plugin: $plugin"
        curl -s -X POST -u "$JENKINS_USER:$JENKINS_PASSWORD" \
            -H "$crumb" \
            -d "plugin.$plugin=" \
            "$JENKINS_URL/pluginManager/installNecessaryPlugins" > /dev/null
        
        # Wait for plugin to install
        sleep 5
    done
    
    print_success "All plugins installed successfully!"
}

# Function to create Jenkins pipeline job
create_jenkins_pipeline() {
    print_status "Creating Jenkins pipeline job..."
    
    local crumb=$(get_jenkins_crumb)
    
    # Create the pipeline job
    curl -s -X POST -u "$JENKINS_USER:$JENKINS_PASSWORD" \
        -H "$crumb" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "json={\"name\":\"devops-application-pipeline\",\"mode\":\"NORMAL\",\"from\":\"\",\"Submit\":\"OK\"}" \
        "$JENKINS_URL/createItem?name=devops-application-pipeline" > /dev/null
    
    print_success "Jenkins pipeline job created successfully!"
}

# Function to test the setup
test_setup() {
    print_status "Testing Jenkins setup..."
    
    # Test if Jenkins is accessible
    if curl -s -f -u "$JENKINS_USER:$JENKINS_PASSWORD" "$JENKINS_URL/api/json" > /dev/null; then
        print_success "Jenkins is accessible!"
    else
        print_error "Jenkins is not accessible!"
        return 1
    fi
    
    print_success "Jenkins setup test completed successfully!"
}

# Main execution
main() {
    print_status "Starting simple Jenkins setup..."
    
    # Check if Jenkins is ready
    if ! check_jenkins_ready; then
        print_error "Jenkins is not ready. Please check if Jenkins is running."
        exit 1
    fi
    
    # Install plugins
    install_jenkins_plugins
    
    # Wait for Jenkins to restart after plugin installation
    print_status "Waiting for Jenkins to restart after plugin installation..."
    sleep 30
    check_jenkins_ready
    
    # Create pipeline job
    create_jenkins_pipeline
    
    # Test setup
    test_setup
    
    print_success "Jenkins setup completed successfully!"
    print_status "Jenkins URL: $JENKINS_URL"
    print_status "Username: $JENKINS_USER"
    print_status "Pipeline Job: devops-application-pipeline"
    print_status ""
    print_status "Next steps:"
    print_status "1. Go to Jenkins: $JENKINS_URL"
    print_status "2. Configure the pipeline job manually"
    print_status "3. Set up credentials for Docker Hub and AWS EC2"
    print_status "4. Launch AWS EC2 instance"
    print_status "5. Test the pipeline"
}

# Run main function
main "$@"
