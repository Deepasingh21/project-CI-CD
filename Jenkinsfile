pipeline {
    agent any

    environment {
        AWS_REGION      = "us-east-1"
        ECR_ACCOUNT_ID  = "136549279537"
        ECR_REPO_NAME   = "my-repo"
        IMAGE_TAG       = "latest"
        GIT_REPO        = "https://github.com/Deepasingh21/project-CI-CD.git"
        EC2_INSTANCE_ID = "i-08c6058e4487aa4d6"
        AWS_CREDENTIALS_ID = "Access_ID"    // <-- set this to your Jenkins AWS credentials ID
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

        stage('Deploy to EC2 via SSM') {
            steps {
                withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGION}") {
                    sh label: 'Deploy via SSM', script: '''bash -euo pipefail
REGION="${AWS_REGION}"
ACCOUNT="${ECR_ACCOUNT_ID}"
REPO="${ECR_REPO_NAME}"
TAG="${IMAGE_TAG}"
INSTANCE="${EC2_INSTANCE_ID}"

# Build the commands as a JSON array so SSM receives them cleanly
read -r -d '' CMD_ARR <<'EOF'
[
  "aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com",
  "docker pull ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${REPO}:${TAG}",
  "docker stop my_app_container || true",
  "docker rm my_app_container || true",
  "docker run -d --name my_app_container -p 80:80 ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${REPO}:${TAG}"
]
EOF

CMDID=$(aws ssm send-command \
  --instance-ids "${INSTANCE}" \
  --document-name "AWS-RunShellScript" \
  --parameters "commands=${CMD_ARR}" \
  --comment "Deploy ${REPO}:${TAG}" \
  --region "${REGION}" \
  --query "Command.CommandId" --output text)

echo "SSM CommandId: ${CMDID}"

# poll until finished
while true; do
  STATUS=$(aws ssm get-command-invocation --command-id "${CMDID}" --instance-id "${INSTANCE}" --region "${REGION}" --query 'Status' --output text 2>/dev/null || echo "Pending")
  echo "Invocation status: ${STATUS}"
  case "${STATUS}" in
    Success)
      echo "Command succeeded - printing output"
      aws ssm get-command-invocation --command-id "${CMDID}" --instance-id "${INSTANCE}" --region "${REGION}"
      break
      ;;
    Failed|Cancelled|TimedOut)
      echo "SSM command finished with status: ${STATUS}"
      aws ssm get-command-invocation --command-id "${CMDID}" --instance-id "${INSTANCE}" --region "${REGION}"
      exit 1
      ;;
    *)
      sleep 2
      ;;
  esac
done
'''
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
