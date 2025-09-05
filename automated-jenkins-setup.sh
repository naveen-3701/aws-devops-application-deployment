#!/bin/bash

# Automated Jenkins Setup Script
# This script automates the complete Jenkins setup for DevOps pipeline

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
DOCKER_HUB_USERNAME="naveen3701"
DOCKER_HUB_PASSWORD=""
AWS_EC2_HOST=""
AWS_EC2_KEY_PATH=""

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

# Function to create Jenkins credentials
create_jenkins_credentials() {
    print_status "Creating Jenkins credentials..."
    
    local crumb=$(get_jenkins_crumb)
    
    # Create Docker Hub credentials
    if [ -n "$DOCKER_HUB_PASSWORD" ]; then
        print_status "Creating Docker Hub credentials..."
        curl -s -X POST -u "$JENKINS_USER:$JENKINS_PASSWORD" \
            -H "$crumb" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "json={\"\":\"4\",\"credentials\":{\"scope\":\"GLOBAL\",\"id\":\"docker-hub-credentials\",\"username\":\"$DOCKER_HUB_USERNAME\",\"password\":\"$DOCKER_HUB_PASSWORD\",\"description\":\"Docker Hub credentials\",\"stapler-class\":\"com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl\",\"\$class\":\"com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl\"}}" \
            "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" > /dev/null
        print_success "Docker Hub credentials created!"
    fi
    
    # Create AWS EC2 Host credential
    if [ -n "$AWS_EC2_HOST" ]; then
        print_status "Creating AWS EC2 Host credential..."
        curl -s -X POST -u "$JENKINS_USER:$JENKINS_PASSWORD" \
            -H "$crumb" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "json={\"\":\"4\",\"credentials\":{\"scope\":\"GLOBAL\",\"id\":\"aws-ec2-host\",\"secret\":\"$AWS_EC2_HOST\",\"description\":\"AWS EC2 Host IP\",\"stapler-class\":\"com.cloudbees.plugins.credentials.impl.StringCredentialsImpl\",\"\$class\":\"com.cloudbees.plugins.credentials.impl.StringCredentialsImpl\"}}" \
            "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" > /dev/null
        print_success "AWS EC2 Host credential created!"
    fi
    
    # Create AWS EC2 Key credential
    if [ -n "$AWS_EC2_KEY_PATH" ] && [ -f "$AWS_EC2_KEY_PATH" ]; then
        print_status "Creating AWS EC2 Key credential..."
        local key_content=$(base64 -w 0 "$AWS_EC2_KEY_PATH")
        curl -s -X POST -u "$JENKINS_USER:$JENKINS_PASSWORD" \
            -H "$crumb" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "json={\"\":\"4\",\"credentials\":{\"scope\":\"GLOBAL\",\"id\":\"aws-ec2-key\",\"secretBytes\":\"$key_content\",\"description\":\"AWS EC2 Key file\",\"stapler-class\":\"com.cloudbees.plugins.credentials.impl.FileCredentialsImpl\",\"\$class\":\"com.cloudbees.plugins.credentials.impl.FileCredentialsImpl\"}}" \
            "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" > /dev/null
        print_success "AWS EC2 Key credential created!"
    fi
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
    
    # Configure the pipeline job
    local config_xml=$(cat << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.50">
  <description>DevOps Application Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <jenkins.model.BuildDiscarderProperty>
      <strategy class="hudson.tasks.LogRotator">
        <daysToKeep>10</daysToKeep>
        <numToKeep>5</numToKeep>
        <artifactDaysToKeep>-1</artifactDaysToKeep>
        <artifactNumToKeep>-1</artifactNumToKeep>
      </strategy>
    </jenkins.model.BuildDiscarderProperty>
    <hudson.plugins.discard__build.DiscardBuildProperty>
      <strategy class="hudson.plugins.discard__build.DiscardOldBuildStrategy">
        <daysToKeepStr>10</daysToKeepStr>
        <numToKeepStr>5</numToKeepStr>
        <artifactDaysToKeepStr>-1</artifactDaysToKeepStr>
        <artifactNumToKeepStr>-1</artifactNumToKeepStr>
      </strategy>
    </hudson.plugins.discard__build.DiscardBuildProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.95">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.15.0">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/naveen-3701/aws-devops-application-deployment.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/dev</name>
        </hudson.plugins.git.BranchSpec>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>false</lightweight>
  </definition>
  <triggers>
    <hudson.triggers.SCMTrigger>
      <spec>H/5 * * * *</spec>
    </hudson.triggers.SCMTrigger>
  </triggers>
  <disabled>false</disabled>
</flow-definition>
EOF
)
    
    curl -s -X POST -u "$JENKINS_USER:$JENKINS_PASSWORD" \
        -H "$crumb" \
        -H "Content-Type: application/xml" \
        -d "$config_xml" \
        "$JENKINS_URL/job/devops-application-pipeline/config.xml" > /dev/null
    
    print_success "Jenkins pipeline job created successfully!"
}

# Function to setup GitHub webhook
setup_github_webhook() {
    print_status "Setting up GitHub webhook..."
    print_warning "You need to manually set up the GitHub webhook:"
    print_status "1. Go to your GitHub repository: https://github.com/naveen-3701/aws-devops-application-deployment"
    print_status "2. Navigate to Settings → Webhooks"
    print_status "3. Click 'Add webhook'"
    print_status "4. Configure:"
    print_status "   - Payload URL: $JENKINS_URL/github-webhook/"
    print_status "   - Content type: application/json"
    print_status "   - Events: Just the push event"
    print_status "   - Active: ✓"
    print_status "5. Click 'Add webhook'"
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
    
    # Test if pipeline job exists
    if curl -s -f -u "$JENKINS_USER:$JENKINS_PASSWORD" "$JENKINS_URL/job/devops-application-pipeline/api/json" > /dev/null; then
        print_success "Pipeline job exists!"
    else
        print_error "Pipeline job does not exist!"
        return 1
    fi
    
    print_success "Jenkins setup test completed successfully!"
}

# Main execution
main() {
    print_status "Starting automated Jenkins setup..."
    
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
    
    # Create credentials
    create_jenkins_credentials
    
    # Create pipeline job
    create_jenkins_pipeline
    
    # Setup GitHub webhook instructions
    setup_github_webhook
    
    # Test setup
    test_setup
    
    print_success "Jenkins setup completed successfully!"
    print_status "Jenkins URL: $JENKINS_URL"
    print_status "Username: $JENKINS_USER"
    print_status "Pipeline Job: devops-application-pipeline"
    print_status ""
    print_status "Next steps:"
    print_status "1. Set up GitHub webhook (see instructions above)"
    print_status "2. Launch AWS EC2 instance"
    print_status "3. Update credentials with EC2 details"
    print_status "4. Test the pipeline"
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --docker-password PASSWORD    Docker Hub password"
    echo "  -e, --ec2-host HOST              AWS EC2 host IP"
    echo "  -k, --ec2-key PATH               AWS EC2 key file path"
    echo "  -h, --help                       Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -d 'your-docker-password' -e '1.2.3.4' -k '/path/to/key.pem'"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--docker-password)
            DOCKER_HUB_PASSWORD="$2"
            shift 2
            ;;
        -e|--ec2-host)
            AWS_EC2_HOST="$2"
            shift 2
            ;;
        -k|--ec2-key)
            AWS_EC2_KEY_PATH="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Run main function
main "$@"
