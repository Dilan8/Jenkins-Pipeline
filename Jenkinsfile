pipeline {
    agent any

    environment {
        AWS_REGION        = 'ap-southeast-2'
        ECR_REGISTRY      = '409324389697.dkr.ecr.ap-southeast-2.amazonaws.com'
        ECR_REPO          = 'cicd-react-app'
        IMAGE_TAG         = 'latest'
        ECS_CLUSTER       = 'cicd-cluster'
        ECS_SERVICE       = 'cicd-react-app-service'
    }

    stages {

        stage('Install') {
            steps {
                dir('react-app') {
                    sh 'npm install'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${ECR_REPO}:${IMAGE_TAG} .'
            }
        }

        stage('Push to ECR') {
            steps {
                sh '''
                    # Login to ECR
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS --password-stdin ${ECR_REGISTRY}

                    # Tag image with ECR URL
                    docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}

                    # Push to ECR
                    docker push ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}
                '''
            }
        }

        stage('Deploy to ECS') {
            steps {
                sh '''
                    aws ecs update-service \
                        --cluster ${ECS_CLUSTER} \
                        --service ${ECS_SERVICE} \
                        --force-new-deployment \
                        --region ${AWS_REGION}
                '''
            }
        }

    }

    post {
        success {
            echo '✅ Pipeline completed — app deployed to ECS!'
        }
        failure {
            echo '❌ Pipeline failed — check the logs above'
        }
    }
}