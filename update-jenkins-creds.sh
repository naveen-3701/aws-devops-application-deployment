#!/bin/bash

JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin123"

# Get Jenkins crumb
CRUMB=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,%22:%22,//crumb)")

# Update AWS EC2 Host credential
curl -s -X POST -u "$JENKINS_USER:$JENKINS_PASSWORD" \
    -H "$CRUMB" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "json={\"\":\"4\",\"credentials\":{\"scope\":\"GLOBAL\",\"id\":\"aws-ec2-host\",\"secret\":\"54.172.238.185\",\"description\":\"AWS EC2 Host IP\",\"stapler-class\":\"com.cloudbees.plugins.credentials.impl.StringCredentialsImpl\",\"$class\":\"com.cloudbees.plugins.credentials.impl.StringCredentialsImpl\"}}" \
    "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" > /dev/null

# Update Docker Hub credentials
curl -s -X POST -u "$JENKINS_USER:$JENKINS_PASSWORD" \
    -H "$CRUMB" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "json={\"\":\"4\",\"credentials\":{\"scope\":\"GLOBAL\",\"id\":\"docker-hub-credentials\",\"username\":\"naveen3701\",\"password\":\"your-docker-password\",\"description\":\"Docker Hub credentials\",\"stapler-class\":\"com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl\",\"$class\":\"com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl\"}}" \
    "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" > /dev/null

echo "Jenkins credentials updated!"
