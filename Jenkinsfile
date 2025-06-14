pipeline {
    agent {
        label 'springboot_node'  // Node label where Docker is available
    }

    environment {
        IMAGE_ALIAS = "springboot"
        IMAGE_TAG = "1"
        AWS_DEFAULT_REGION = 'us-east-2'
    }

    stages {
        stage('Pre-cleanup') {
            steps {
                sh '''
                    echo "🔄 Attempting to delete existing Kubernetes resources and EKS cluster..."

                    if command -v kubectl >/dev/null 2>&1; then
                        echo "✅ kubectl found. Checking for existing deployment..."
                    
                        if kubectl get deployment springboot >/dev/null 2>&1; then
                            echo "🗑️ Deleting existing deployment..."
                            kubectl delete -f deployment.yml
                            echo "⏳ Waiting for resources to fully terminate..."
                            sleep 60
                        else
                            echo "⚠️ No existing deployment found. Skipping deletion and sleep."
                        fi
                    else
                        echo "ℹ️ kubectl not installed. Skipping Kubernetes resource check and deletion."
                    fi


                    if command -v eksctl >/dev/null 2>&1; then
                        echo "✅ eksctl found. Checking for existing EKS cluster..."
                    
                        if eksctl get cluster --name demo-cluster --region ${AWS_DEFAULT_REGION} >/dev/null 2>&1; then
                            echo "🗑️ Cluster found. Deleting EKS cluster..."
                            eksctl delete cluster --name demo-cluster --region ${AWS_DEFAULT_REGION}
                            echo "⏳ Waiting for cluster deletion to complete..."
                            sleep 60
                        else
                            echo "⚠️ No existing cluster found. Skipping deletion and sleep."
                        fi
                    else
                        echo "ℹ️ eksctl not installed. Skipping EKS cluster deletion."
                    fi

                '''
            }
        }
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
                withCredentials([usernamePassword(credentialsId: 'docker_credential', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
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
                withCredentials([usernamePassword(credentialsId: 'docker_credential', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
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
                        aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
                        aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
                        aws configure set region ${AWS_DEFAULT_REGION}
                        aws configure set output json
                        echo "Testing AWS credentials..."
                        aws sts get-caller-identity || (echo '❌ Invalid AWS credentials' && exit 1)
                        
                        if eksctl get cluster --region=us-east-2 --name=demo-cluster >/dev/null 2>&1; then
                          echo "Cluster already exists, skipping creation."
                        else
                            eksctl create cluster \
                                --name demo-cluster \
                                --version 1.30 \
                                --region ${AWS_DEFAULT_REGION} \
                                --nodegroup-name demo-workers \
                                --node-type t2.micro \
                                --nodes 3 \
                                --nodes-min 1 \
                                --nodes-max 4 \
                                --managed
                            sleep 60
                        fi
                        
                        aws eks update-kubeconfig --name demo-cluster --region ${AWS_DEFAULT_REGION}
                        sleep 60

                        kubectl apply -f deployment.yml
                        sleep 30
                        kubectl get all -o wide
                        SVC_DNS=\$(kubectl get svc springboot -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")
                        echo "🔗 Spring Boot App is available at: http://\$SVC_DNS:9000"
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
