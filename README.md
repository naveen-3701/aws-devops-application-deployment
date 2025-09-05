# DevOps Application Deployment

A complete end-to-end DevOps pipeline for deploying a React application to production using Docker, Jenkins, AWS EC2, and monitoring systems.

## 📋 Project Overview

This project demonstrates a production-ready deployment pipeline that includes:

- **React Application**: Containerized with Docker and Nginx
- **CI/CD Pipeline**: Jenkins with GitHub integration
- **Container Registry**: Docker Hub with dev and prod repositories
- **Cloud Deployment**: AWS EC2 t2.micro instance
- **Monitoring**: Prometheus, Grafana, and health checks
- **Automation**: Bash scripts for build and deployment

## 🏗️ Architecture

```
GitHub Repository → Jenkins → Docker Hub → AWS EC2 → Monitoring
```

### Workflow:
1. **Dev Branch**: Code push triggers Jenkins → Builds and pushes to `dev` Docker Hub repo
2. **Main Branch**: Code push triggers Jenkins → Builds and pushes to `prod` Docker Hub repo
3. **Deployment**: Jenkins automatically deploys to AWS EC2 instance
4. **Monitoring**: Health checks and monitoring systems track application status

## 🚀 Quick Start

### Prerequisites
- Docker installed
- AWS CLI configured
- Jenkins server
- Docker Hub account
- AWS EC2 instance

### 1. Clone and Setup
```bash
git clone https://github.com/naveen-3701/aws-devops-application-deployment.git
cd aws-devops-application-deployment
```

### 2. Docker Setup
```bash
# Build and test locally
docker build -t devops-application:test .
docker run -d -p 3000:80 --name devops-test devops-application:test
curl http://localhost:3000
```

### 3. Build and Deploy
```bash
# Build for dev environment
./build.sh dev

# Deploy to AWS EC2
./deploy.sh dev YOUR_EC2_IP ~/path/to/your-key.pem
```

## 📁 Project Structure

```
devops-build/
├── build/                    # React application build files
├── monitoring/               # Monitoring configuration
│   ├── docker-compose.yml   # Prometheus + Grafana setup
│   ├── prometheus.yml       # Prometheus configuration
│   └── alertmanager.yml     # Alert manager configuration
├── Dockerfile               # Docker image definition
├── docker-compose.yml       # Local development setup
├── nginx.conf              # Nginx configuration
├── build.sh                # Build script for Docker images
├── deploy.sh               # Deployment script for AWS EC2
├── Jenkinsfile             # Jenkins pipeline configuration
├── setup-dockerhub.sh      # Docker Hub setup instructions
├── setup-jenkins.sh        # Jenkins setup instructions
├── setup-aws-ec2.sh        # AWS EC2 setup instructions
├── setup-monitoring.sh     # Monitoring setup instructions
├── .gitignore              # Git ignore file
├── .dockerignore           # Docker ignore file
└── README.md               # This file
```

## 🐳 Docker Configuration

### Dockerfile
Multi-stage build using Nginx Alpine for serving the React application:
- Copies built React app to Nginx
- Configures security headers
- Exposes port 80
- Includes health check endpoint

### Docker Compose
Local development setup with:
- Port mapping (80:80)
- Health checks
- Restart policies
- Environment variables

## 🔧 Build Scripts

### build.sh
Automated Docker image building and pushing:
- Supports dev and prod environments
- Automatic tagging with build numbers
- Docker Hub integration
- Error handling and logging

### deploy.sh
AWS EC2 deployment automation:
- SSH connection management
- Docker installation on EC2
- Container deployment
- Health verification
- Rollback capabilities

## 🔄 CI/CD Pipeline

### Jenkins Configuration
- **Trigger**: GitHub webhook on push to dev/main branches
- **Build**: Docker image creation
- **Push**: Automatic push to Docker Hub
- **Deploy**: AWS EC2 deployment
- **Verify**: Health checks and monitoring

### Branch Strategy
- **dev branch**: Development environment → `dev` Docker Hub repo
- **main branch**: Production environment → `prod` Docker Hub repo

## ☁️ AWS EC2 Deployment

### Instance Requirements
- **Type**: t2.micro (Free Tier)
- **OS**: Amazon Linux 2 or Ubuntu 20.04 LTS
- **Storage**: 8 GB minimum
- **Security Groups**: HTTP (80), SSH (22), HTTPS (443)

### Security Configuration
- **HTTP Access**: Open to all (0.0.0.0/0)
- **SSH Access**: Restricted to your IP only
- **Docker**: Installed and configured
- **Firewall**: Properly configured

## 📊 Monitoring Setup

### Health Check Endpoints
- **Main App**: `http://your-ec2-ip/`
- **Health Check**: `http://your-ec2-ip/health`
- **Connectivity**: `http://your-ec2-ip/robots.txt`

### Monitoring Options
1. **Prometheus + Grafana**: Full monitoring stack
2. **Uptime Robot**: Cloud-based monitoring
3. **Custom Scripts**: Simple health checks
4. **AWS CloudWatch**: Native AWS monitoring

### Alerting
- Application downtime notifications
- Performance degradation alerts
- System resource monitoring
- Deployment status updates

## 🛠️ Setup Instructions

### 1. Docker Hub Setup
```bash
./setup-dockerhub.sh
```
Creates two repositories:
- `naveen-3701/dev` (Public)
- `naveen-3701/prod` (Private)

### 2. Jenkins Setup
```bash
./setup-jenkins.sh
```
Complete Jenkins installation and configuration guide.

### 3. AWS EC2 Setup
```bash
./setup-aws-ec2.sh
```
EC2 instance creation and configuration instructions.

### 4. Monitoring Setup
```bash
./setup-monitoring.sh
```
Monitoring system installation and configuration.

## 🔍 Testing and Verification

### Local Testing
```bash
# Build and test Docker image
docker build -t devops-application:test .
docker run -d -p 3000:80 --name devops-test devops-application:test
curl http://localhost:3000
curl http://localhost:3000/health
```

### Deployment Testing
```bash
# Test deployment script
./deploy.sh dev YOUR_EC2_IP ~/path/to/your-key.pem

# Verify deployment
curl http://YOUR_EC2_IP
curl http://YOUR_EC2_IP/health
```

### Pipeline Testing
1. Make changes to code
2. Push to `dev` branch
3. Check Jenkins for automatic build
4. Verify Docker Hub for new image
5. Check AWS EC2 for deployment

## 📈 Performance and Scaling

### Resource Optimization
- **Container**: Lightweight Nginx Alpine
- **Caching**: Static asset caching
- **Compression**: Gzip compression enabled
- **Security**: Security headers configured

### Scaling Options
- **Horizontal**: Multiple EC2 instances
- **Load Balancer**: AWS Application Load Balancer
- **Auto Scaling**: AWS Auto Scaling Groups
- **Container Orchestration**: ECS or EKS

## 🔒 Security Best Practices

### Application Security
- Security headers in Nginx
- Non-root container user
- Minimal attack surface
- Regular security updates

### Infrastructure Security
- SSH key-based authentication
- Security group restrictions
- IAM role-based access
- VPC network isolation

### CI/CD Security
- Secure credential management
- Encrypted communication
- Access control policies
- Audit logging

## 🚨 Troubleshooting

### Common Issues

#### Docker Build Issues
```bash
# Check Docker daemon
docker info

# Clean up Docker
docker system prune -a
```

#### Deployment Issues
```bash
# Check SSH connection
ssh -i your-key.pem ec2-user@YOUR_EC2_IP

# Check Docker on EC2
docker ps
docker logs devops-application
```

#### Jenkins Issues
- Check Jenkins logs
- Verify GitHub webhook
- Check Docker Hub credentials
- Verify AWS EC2 access

### Health Check Commands
```bash
# Application health
curl -f http://YOUR_EC2_IP/health

# Container status
docker ps --filter name=devops-application

# System resources
htop
df -h
free -h
```

## 📞 Support and Resources

### Documentation
- [Docker Documentation](https://docs.docker.com/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Prometheus Documentation](https://prometheus.io/docs/)

### Community
- [Docker Community](https://forums.docker.com/)
- [Jenkins Community](https://community.jenkins.io/)
- [AWS Community](https://aws.amazon.com/community/)

## 🎯 Success Criteria

✅ **Application Deployed**: React app running on AWS EC2  
✅ **CI/CD Pipeline**: Jenkins automated deployment  
✅ **Container Registry**: Docker Hub integration  
✅ **Monitoring**: Health checks and alerting  
✅ **Documentation**: Complete setup guide  
✅ **Automation**: Build and deployment scripts  
✅ **Security**: Proper access controls  
✅ **Scalability**: Production-ready configuration  

## 📝 Submission Requirements

### Required Information
- **GitHub Repository**: https://github.com/naveen-3701/aws-devops-application-deployment.git
- **Deployed Site URL**: http://YOUR_EC2_IP
- **Docker Image Names**: 
  - `naveen-3701/dev:latest`
  - `naveen-3701/prod:latest`

### Screenshots Required
- Jenkins login page and configuration
- AWS EC2 console and security groups
- Docker Hub repositories with image tags
- Deployed application page
- Monitoring health check status

## 🏆 Project Status

**Status**: ✅ Complete and Production Ready  
**Last Updated**: September 2025  
**Version**: 1.0.0  
**Author**: DevOps Team  

---

🎉 **Congratulations! Your DevOps application deployment pipeline is now complete and ready for production use!**
