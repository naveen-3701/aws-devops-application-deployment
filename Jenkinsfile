pipeline {
    agent any
    
    environment {
        DOCKER_HUB_USERNAME = 'naveen3701'
        DEV_REPO = 'naveen-3701-devops-app-dev'
        PROD_REPO = 'naveen-3701-devops-app-prod'
        DEV_TAG = 'dev'
        PROD_TAG = 'prod'
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Code checked out successfully"
                echo "Branch: ${env.BRANCH_NAME}"
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'dev') {
                        echo "Building DEV image"
                        sh """
                            docker build -t ${DOCKER_HUB_USERNAME}/${DEV_REPO}:${DEV_TAG} .
                            docker tag ${DOCKER_HUB_USERNAME}/${DEV_REPO}:${DEV_TAG} ${DOCKER_HUB_USERNAME}/${DEV_REPO}:${DEV_TAG}-${BUILD_NUMBER}
                        """
                    } else if (env.BRANCH_NAME == 'main') {
                        echo "Building PROD image"
                        sh """
                            docker build -t ${DOCKER_HUB_USERNAME}/${PROD_REPO}:${PROD_TAG} .
                            docker tag ${DOCKER_HUB_USERNAME}/${PROD_REPO}:${PROD_TAG} ${DOCKER_HUB_USERNAME}/${PROD_REPO}:${PROD_TAG}-${BUILD_NUMBER}
                        """
                    } else {
                        echo "Building both DEV and PROD images"
                        sh """
                            docker build -t ${DOCKER_HUB_USERNAME}/${DEV_REPO}:${DEV_TAG} .
                            docker build -t ${DOCKER_HUB_USERNAME}/${PROD_REPO}:${PROD_TAG} .
                            docker tag ${DOCKER_HUB_USERNAME}/${DEV_REPO}:${DEV_TAG} ${DOCKER_HUB_USERNAME}/${DEV_REPO}:${DEV_TAG}-${BUILD_NUMBER}
                            docker tag ${DOCKER_HUB_USERNAME}/${PROD_REPO}:${PROD_TAG} ${DOCKER_HUB_USERNAME}/${PROD_REPO}:${PROD_TAG}-${BUILD_NUMBER}
                        """
                    }
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                        
                        if (env.BRANCH_NAME == 'dev') {
                            echo "Pushing DEV image to Docker Hub"
                            sh """
                                docker push ${DOCKER_HUB_USERNAME}/${DEV_REPO}:${DEV_TAG}
                                docker push ${DOCKER_HUB_USERNAME}/${DEV_REPO}:${DEV_TAG}-${BUILD_NUMBER}
                            """
                        } else if (env.BRANCH_NAME == 'main') {
                            echo "Pushing PROD image to Docker Hub"
                            sh """
                                docker push ${DOCKER_HUB_USERNAME}/${PROD_REPO}:${PROD_TAG}
                                docker push ${DOCKER_HUB_USERNAME}/${PROD_REPO}:${PROD_TAG}-${BUILD_NUMBER}
                            """
                        } else {
                            echo "Pushing both DEV and PROD images to Docker Hub"
                            sh """
                                docker push ${DOCKER_HUB_USERNAME}/${DEV_REPO}:${DEV_TAG}
                                docker push ${DOCKER_HUB_USERNAME}/${PROD_REPO}:${PROD_TAG}
                                docker push ${DOCKER_HUB_USERNAME}/${DEV_REPO}:${DEV_TAG}-${BUILD_NUMBER}
                                docker push ${DOCKER_HUB_USERNAME}/${PROD_REPO}:${PROD_TAG}-${BUILD_NUMBER}
                            """
                        }
                    }
                }
            }
        }
        
        stage('Deploy to AWS EC2') {
            when {
                anyOf {
                    branch 'dev'
                    branch 'main'
                }
            }
            steps {
                script {
                    withCredentials([string(credentialsId: 'aws-ec2-host', variable: 'AWS_EC2_HOST'), file(credentialsId: 'aws-ec2-key', variable: 'AWS_EC2_KEY')]) {
                        if (env.BRANCH_NAME == 'dev') {
                            echo "Deploying DEV version to AWS EC2"
                            sh """
                                chmod 600 ${AWS_EC2_KEY}
                                ./deploy.sh dev ${AWS_EC2_HOST} ${AWS_EC2_KEY}
                            """
                        } else if (env.BRANCH_NAME == 'main') {
                            echo "Deploying PROD version to AWS EC2"
                            sh """
                                chmod 600 ${AWS_EC2_KEY}
                                ./deploy.sh prod ${AWS_EC2_HOST} ${AWS_EC2_KEY}
                            """
                        }
                    }
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'aws-ec2-host', variable: 'AWS_EC2_HOST')]) {
                        echo "Performing health check on deployed application"
                        sh """
                            sleep 30
                            curl -f http://${AWS_EC2_HOST}/health || echo "Health check failed, but deployment may still be successful"
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Clean up Docker images
            sh """
                docker rmi ${DOCKER_HUB_USERNAME}/${DEV_REPO}:${DEV_TAG} || true
                docker rmi ${DOCKER_HUB_USERNAME}/${PROD_REPO}:${PROD_TAG} || true
                docker rmi ${DOCKER_HUB_USERNAME}/${DEV_REPO}:${DEV_TAG}-${BUILD_NUMBER} || true
                docker rmi ${DOCKER_HUB_USERNAME}/${PROD_REPO}:${PROD_TAG}-${BUILD_NUMBER} || true
            """
        }
        
        success {
            echo "Pipeline executed successfully!"
            // Send success notification
        }
        
        failure {
            echo "Pipeline failed!"
            // Send failure notification
        }
    }
}
