
# create jenkins crredentials
# aws_creds = AWS_ACCESS_KEY_ID AMD ACCESS_SECTER_KEY
# docker_login = DOCKER USERNAME AND PASSWORD

pipeline {
    agent {
        label 'Any'  // Node label where Docker is available
    }

    environment {
        IMAGE_ALIAS = "springboot"
        IMAGE_TAG = "1"
        AWS_DEFAULT_REGION = 'us-east-2'
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
                withCredentials([usernamePassword(credentialsId: 'docker_login', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
                    sh """
                        sudo docker rmi ${DOCKERHUB_USER}/${IMAGE_ALIAS}:${IMAGE_TAG} || true
                        sudo docker build -t ${DOCKERHUB_USER}/${IMAGE_ALIAS}:${IMAGE_TAG} .
                        sudo docker login -u ${DOCKERHUB_USER} -p ${DOCKERHUB_PASS}
                        sudo docker push ${DOCKERHUB_USER}/${IMAGE_ALIAS}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy Container') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker_login', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
                    sh """
                        sudo docker container stop ${IMAGE_ALIAS} || true
                        sudo docker container rm ${IMAGE_ALIAS} || true
                        sudo docker run -itd -p 8080:8080 --name ${IMAGE_ALIAS} ${DOCKERHUB_USER}/${IMAGE_ALIAS}:${IMAGE_TAG}
                        sudo docker ps
                        echo "Spring Boot app is now accessible on port 9000."
                    """
                }
            }
        }

        stage('Create EKS Cluster and Deploy App') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws_creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh """
                        chmod +x install_tools.sh
                        ./install_tools.sh
                        mkdir -p ~/.aws

                        cat > ~/.aws/credentials <<EOL
[default]
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}
EOL

                        cat > ~/.aws/config <<EOL
[default]
region = ${AWS_DEFAULT_REGION}
output = json
EOL

                        eksctl create cluster \\
                            --name demo-cluster \\
                            --version 1.30 \\
                            --region ${AWS_DEFAULT_REGION} \\
                            --nodegroup-name demo-workers \\
                            --node-type t2.micro \\
                            --nodes 3 \\
                            --nodes-min 1 \\
                            --nodes-max 4 \\
                            --managed

                        sleep 300

                        aws eks update-kubeconfig --name demo-cluster --region ${AWS_DEFAULT_REGION}
                        sleep 60

                        kubectl apply -f deployment.yml
                        sleep 30

                        kubectl get all -o wide
                    """
                }
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
