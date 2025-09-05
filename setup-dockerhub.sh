#!/bin/bash

# Docker Hub Setup Script
# This script helps set up Docker Hub repositories for dev and prod

set -e

# Configuration
DOCKER_HUB_USERNAME="naveen-3701"
IMAGE_NAME="devops-application"
DEV_REPO="devops-app-dev"
PROD_REPO="devops-app-prod"

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

print_status "Docker Hub Repository Setup Instructions"
echo ""
print_status "You need to create two repositories on Docker Hub:"
echo ""
print_status "1. DEV Repository (Public):"
print_status "   Repository Name: ${DOCKER_HUB_USERNAME}/${DEV_REPO}"
print_status "   Visibility: Public"
print_status "   Description: DevOps Application - Development Environment"
echo ""
print_status "2. PROD Repository (Private):"
print_status "   Repository Name: ${DOCKER_HUB_USERNAME}/${PROD_REPO}"
print_status "   Visibility: Private"
print_status "   Description: DevOps Application - Production Environment"
echo ""
print_status "Steps to create repositories:"
print_status "1. Go to https://hub.docker.com/"
print_status "2. Sign in with your Docker Hub account"
print_status "3. Click 'Create Repository'"
print_status "4. Create the repositories as specified above"
echo ""
print_status "After creating repositories, you can test the build script:"
print_status "  ./build.sh dev    # Build and push dev image"
print_status "  ./build.sh prod   # Build and push prod image"
echo ""
print_status "Docker Hub URLs will be:"
print_status "  Dev:  https://hub.docker.com/r/${DOCKER_HUB_USERNAME}/${DEV_REPO}"
print_status "  Prod: https://hub.docker.com/r/${DOCKER_HUB_USERNAME}/${PROD_REPO}"