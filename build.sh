#!/bin/bash

# DevOps Application Build Script
# This script builds Docker images for both dev and prod environments

set -e  # Exit on any error

# Configuration
DOCKER_HUB_USERNAME="naveen3701"
DEV_REPO="naveen-3701-devops-app-dev"
PROD_REPO="naveen-3701-devops-app-prod"
DEV_TAG="dev"
PROD_TAG="prod"
BUILD_NUMBER=${BUILD_NUMBER:-$(date +%Y%m%d%H%M%S)}

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

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to login to Docker Hub
docker_login() {
    print_status "Logging into Docker Hub..."
    if ! docker login; then
        print_error "Failed to login to Docker Hub"
        exit 1
    fi
    print_success "Successfully logged into Docker Hub"
}

# Function to build Docker image
build_image() {
    local tag=$1
    local repo=$2
    local full_tag="${DOCKER_HUB_USERNAME}/${repo}:${tag}"
    
    print_status "Building Docker image with tag: ${full_tag}"
    
    if docker build -t "${full_tag}" .; then
        print_success "Successfully built image: ${full_tag}"
    else
        print_error "Failed to build image: ${full_tag}"
        exit 1
    fi
}

# Function to push Docker image
push_image() {
    local tag=$1
    local repo=$2
    local full_tag="${DOCKER_HUB_USERNAME}/${repo}:${tag}"
    
    print_status "Pushing Docker image: ${full_tag}"
    
    if docker push "${full_tag}"; then
        print_success "Successfully pushed image: ${full_tag}"
    else
        print_error "Failed to push image: ${full_tag}"
        exit 1
    fi
}

# Function to tag image with build number
tag_with_build_number() {
    local tag=$1
    local repo=$2
    local full_tag="${DOCKER_HUB_USERNAME}/${repo}:${tag}"
    local build_tag="${DOCKER_HUB_USERNAME}/${repo}:${tag}-${BUILD_NUMBER}"
    
    print_status "Tagging image with build number: ${build_tag}"
    
    if docker tag "${full_tag}" "${build_tag}"; then
        print_success "Successfully tagged image: ${build_tag}"
        push_image "${tag}-${BUILD_NUMBER}" "${repo}"
    else
        print_error "Failed to tag image: ${build_tag}"
        exit 1
    fi
}

# Main execution
main() {
    print_status "Starting DevOps Application Build Process"
    print_status "Build Number: ${BUILD_NUMBER}"
    print_status "Docker Hub Username: ${DOCKER_HUB_USERNAME}"
    
    # Check if Docker is running
    check_docker
    
    # Login to Docker Hub
    docker_login
    
    # Determine which environment to build based on branch or parameter
    if [ "$1" = "dev" ]; then
        print_status "Building for DEV environment"
        build_image "${DEV_TAG}" "${DEV_REPO}"
        push_image "${DEV_TAG}" "${DEV_REPO}"
        tag_with_build_number "${DEV_TAG}" "${DEV_REPO}"
    elif [ "$1" = "prod" ]; then
        print_status "Building for PROD environment"
        build_image "${PROD_TAG}" "${PROD_REPO}"
        push_image "${PROD_TAG}" "${PROD_REPO}"
        tag_with_build_number "${PROD_TAG}" "${PROD_REPO}"
    else
        print_status "Building for both DEV and PROD environments"
        build_image "${DEV_TAG}" "${DEV_REPO}"
        build_image "${PROD_TAG}" "${PROD_REPO}"
        push_image "${DEV_TAG}" "${DEV_REPO}"
        push_image "${PROD_TAG}" "${PROD_REPO}"
        tag_with_build_number "${DEV_TAG}" "${DEV_REPO}"
        tag_with_build_number "${PROD_TAG}" "${PROD_REPO}"
    fi
    
    print_success "Build process completed successfully!"
    print_status "Images pushed to Docker Hub:"
    print_status "  - ${DOCKER_HUB_USERNAME}/${DEV_REPO}:${DEV_TAG}"
    print_status "  - ${DOCKER_HUB_USERNAME}/${PROD_REPO}:${PROD_TAG}"
    print_status "  - ${DOCKER_HUB_USERNAME}/${DEV_REPO}:${DEV_TAG}-${BUILD_NUMBER}"
    print_status "  - ${DOCKER_HUB_USERNAME}/${PROD_REPO}:${PROD_TAG}-${BUILD_NUMBER}"
}

# Show usage if no arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [dev|prod]"
    echo "  dev  - Build and push dev image"
    echo "  prod - Build and push prod image"
    echo "  (no args) - Build and push both dev and prod images"
    exit 1
fi

# Run main function
main "$@"
