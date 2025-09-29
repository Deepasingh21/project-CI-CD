pipeline {
    agent any

    environment {
        AWS_REGION      = "us-east-1"
        ECR_REPO        = "my-erc-repo-01"
        IMAGE_TAG       = "latest"
        AWS_ACCOUNT_ID  = "207963326787"
        IMAGE_NAME      = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
        GIT_REPO_URL    = "https://github.com/Deepasingh21/project-CI-CD.git"
        GIT_BRANCH      = "main"

        // ✅ Here is where you fix your AWS Access Key
        AWS_ACCESS_KEY_ID = "AKIATA24URFBZVZXIIVZ"
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Cloning repo from GitHub..."
                git branch: "${GIT_BRANCH}", url: "${GIT_REPO_URL}"
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${IMAGE_NAME}"
                sh "docker build -t ${IMAGE_NAME} ."
            }
        }

        stage('Login to AWS ECR') {
            steps {
                // 🔒9ZXxx7GfhMQykdhL3iCI0Gxlp+WQF8SsrjBSNZCG
                withCredentials([
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh """
                        export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                        export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    """
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                echo "Pushing Docker image to ECR: ${IMAGE_NAME}"
                sh "docker push ${IMAGE_NAME}"
            }
        }
    }

    post {
        success {
            echo "✅ Docker image pushed successfully to ECR: ${IMAGE_NAME}"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
