pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"                          // 🔴 CHANGE: Your AWS region
        ECR_ACCOUNT_ID = "207963326787"                   // 🔴 CHANGE: Your AWS Account ID
        ECR_REPO_NAME = "my-erc-repo-01"                     // 🔴 CHANGE: Your ECR repo name
        IMAGE_TAG = "latest"                              // 🔴 CHANGE: Desired tag
        GIT_REPO = "https://github.com/Deepasingh21/project-CI-CD.git" // 🔴 CHANGE: Your GitHub repo
        EC2_INSTANCE_ID = "i-0f99a5d4fd5f288d7"           // 🔴 CHANGE: Your EC2 instance ID
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: "${env.GIT_REPO}"
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${env.ECR_REPO_NAME}:${env.IMAGE_TAG}")
                }
            }
        }

        stage('Login to ECR') {
            steps {
                script {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    """
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    sh """
                        docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}
                        docker push ${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to EC2 via AWS SSM') {
            steps {
                script {
                    sh """
                        aws ssm send-command \\
                        --targets "Key=instanceIds,Values=${EC2_INSTANCE_ID}" \\
                        --document-name "AWS-RunShellScript" \\
                        --region ${AWS_REGION} \\
                        --comment "Deploy Docker image" \\
                        --parameters 'commands=[
                            "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com",
                            "docker pull ${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}",
                            "docker stop my_app_container || true",
                            "docker rm my_app_container || true",
                            "docker run -d --name my_app_container -p 80:80 ${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}"
                        ]'
                    """
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished."
        }
    }
}
