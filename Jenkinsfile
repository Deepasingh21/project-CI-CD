// Jenkinsfile (Declarative Pipeline)
// Purpose: build Docker image from the repository's Dockerfile, push to AWS ECR,
// and deploy the image on a remote EC2 by SSH (pull from ECR and run).
// -----------------------------
// IMPORTANT: lines with "### CHANGE THIS" mark values you MUST update for your environment.
// Also note the credential IDs used below: 'aws-credentials-id' and 'ec2-ssh-key' — change them
// in Jenkins or update the credentials IDs to match your Jenkins setup.
// -----------------------------

pipeline {
  agent any

  environment {
    // --- REQUIRED: update these ---
    AWS_REGION      = 'us-east-1'                 // ### CHANGE THIS: your AWS region
    ECR_ACCOUNT     = '207963326787'              // ### CHANGE THIS: your AWS account ID
    ECR_REPOSITORY  = 'my-erc-repo-01'                    // ### CHANGE THIS: ECR repo name you want

    // Image tag (uses build number if available)
    IMAGE_TAG       = "${env.BUILD_NUMBER ?: 'local'}"

    // Derived — usually you don't change
    ECR_REGISTRY    = "${ECR_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"

    // --- REQUIRED for remote EC2 deploy ---
    EC2_USER        = 'ubuntu'                  // ### CHANGE THIS: SSH username for your EC2
    EC2_HOST        = '34.205.27.91' // ### CHANGE THIS: EC2 public DNS or IP
    CONTAINER_NAME  = 'vigorous_mclaren'          // ### CHANGE THIS: name for the running container
    HOST_PORT       = '80'                        // ### CHANGE THIS: host port on EC2 to expose
    CONTAINER_PORT  = '80'                        // ### CHANGE THIS: container's internal port

    // Credential IDs in Jenkins (create these in Jenkins Credentials and match the IDs):
    AWS_CREDENTIALS_ID = 'aws-credentials-id'    // ### CHANGE THIS if you name credentials differently
    EC2_SSH_CREDENTIAL = 'ec2-ssh-key'           // ### CHANGE THIS if you name credentials differently
  }

  options { timestamps() }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Docker image') {
      steps {
        // Build and tag locally
        sh '''
          docker --version || true
          docker build -f Dockerfile -t ${ECR_REPOSITORY}:${IMAGE_TAG} .
          docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
        '''
      }
    }

    stage('Login to ECR & Push') {
      steps {
        // Uses AWS credentials configured in Jenkins. Two common patterns exist in Jenkins:
        // 1) If you have the "Amazon Web Services Credentials" plugin, use the AWS-binding (shown below).
        // 2) If not, create Jenkins username/password (or secret text) and export AWS env vars manually.
        // The example below uses the AmazonWebServicesCredentialsBinding class (common in many Jenkins setups).

        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS_ID}"]]) {
          sh '''
            # Login to ECR
            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

            # Ensure the repository exists (safe to run repeatedly)
            aws ecr create-repository --repository-name ${ECR_REPOSITORY} --region ${AWS_REGION} || true

            # Push the image to ECR
            docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
          '''
        }
      }
    }

    stage('Deploy to EC2 (pull & run)') {
      steps {
        // SSH to EC2 using Jenkins SSH credentials (private key). The sshagent step is from the 'ssh-agent' plugin.
        // Make sure the Jenkins agent executing this has ssh-client installed.
        sshagent (credentials: ["${EC2_SSH_CREDENTIAL}"]) {
          sh '''
            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} "\
              docker --version || exit 1 && \
              aws --version || true && \
              docker pull ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} && \
              docker stop ${CONTAINER_NAME} || true && \
              docker rm ${CONTAINER_NAME} || true && \
              docker run -d --name ${CONTAINER_NAME} -p ${HOST_PORT}:${CONTAINER_PORT} ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
          '''
        }
      }
    }
  }

  post {
    success {
      echo "Built and deployed ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
    }
    failure {
      echo 'Pipeline failed — check console output and agent environment (docker/aws/ssh availability).'
    }
  }
}
