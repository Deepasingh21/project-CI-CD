pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"                          // 🔴 CHANGE: Your AWS region
        ECR_ACCOUNT_ID = "136549279537"                   // 🔴 CHANGE: Your AWS Account ID
        ECR_REPO_NAME = "my-repo"                  // 🔴 CHANGE: Your ECR repo name
        IMAGE_TAG = "latest"                              // 🔴 CHANGE: Desired tag
        GIT_REPO = "https://github.com/Deepasingh21/project-CI-CD.git" // 🔴 CHANGE: Your GitHub repo
        EC2_INSTANCE_ID = "i-08c6058e4487aa4d6"           // 🔴 CHANGE: Your EC2 instance ID
        AWS_CREDENTIALS_ID = "Access_ID"           // 🔴 CHANGE: Your Jenkins AWS credentials ID
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
                withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGION}") {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    """
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGION}") {
                    sh """
                        docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}
                        docker push ${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to EC2 via AWS SSM') {
            steps {
                withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGION}") {
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


