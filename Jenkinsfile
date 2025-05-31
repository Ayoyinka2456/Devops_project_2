#Unfinished
pipeline {
    agent {
        label 'Any'  // Node label where Docker is available
    }

    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker_login')  // Jenkins credentials ID
        appName = "springboot"
        IMAGE_TAG = "1"
        DOCKER_IMAGE = "${DOCKERHUB_CREDENTIALS_USR}/${appName}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Cleaning workspace and preparing environment..."
                sh '''
                    sudo yum -y install docker
                    sudo systemctl start docker
                    sudo systemctl enable docker
                    sudo systemctl status docker --no-pager
                    sudo rm -rf *
                '''
                git branch: 'main', url: 'https://github.com/Ayoyinka2456/Devops_project_2.git'
            }
        }

        stage('Dockerize') {
            steps {
                echo "Building and pushing Docker image..."
                sh """
                    sudo docker images
                    sudo docker rmi ${DOCKER_IMAGE}:${IMAGE_TAG} || true
                    sudo docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} .
                    sudo docker login -u \"${DOCKERHUB_CREDENTIALS_USR}\" -p \"${DOCKERHUB_CREDENTIALS_PSW}\"
                    sudo docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
                """
            }
        }

        stage('Deploy Container') {
            steps {
                echo "Stopping any existing container and running new one on port 9000..."
                sh """
                    sudo docker container stop ${appName} || true
                    sudo docker container rm ${appName} || true
                    sudo docker run -itd -p 9000:8080 --name ${appName} ${DOCKER_IMAGE}:${IMAGE_TAG}
                    sudo docker ps
                    echo "Spring Boot app is now accessible on port 9000."
                """
            }
        }
    }

    post {
        success {
            echo "✅ Build and deployment completed successfully."
        }
        failure {
            echo "❌ Something went wrong. Please review the logs."
        }
    }
}
