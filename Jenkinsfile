pipeline {
    agent any

    environment {
        SONARQUBE_SCANNER = 'sonar-scanner'
        SONARQUBE_SERVER  = 'SonarQubeServer'
        DOCKER_HOST = "ssh://ec2-user@15.206.91.34"
        IMAGE_NAME = "my-httpd-site"
        IMAGE_TAG = "latest"
        REPO_URL = "https://github.com/avulasurya1992/real-world-sample-project1-multibranch.git"
        REPO_DIR = "real-world-sample-project1-multibranch"
        dockerhost_ssh_key = 'docker-host-creds'
        NEXUS_REGISTRY = "65.0.26.117:8082"
        NEXUS_CREDENTIALS_ID = 'nexus-host-cred'
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Cloning Git repository"
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo "Simulating build step"
                sh 'echo "Build successful"'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    withCredentials([string(credentialsId: 'sonarqube-auth', variable: 'SONAR_TOKEN')]) {
                        sh """
                            ${tool SONARQUBE_SCANNER}/bin/sonar-scanner \\ 
                            -Dsonar.projectKey=sample-project1 \\ 
                            -Dsonar.sources=. \\ 
                            -Dsonar.projectName=sample-project1 \\ 
                            -Dsonar.exclusions=**/Dockerfile \\ 
                            -Dsonar.host.url=http://13.233.113.199:9000 \\ 
                            -Dsonar.login=$SONAR_TOKEN
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 3, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image on remote Docker host"
                sshagent(credentials: [dockerhost_ssh_key]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ec2-user@15.206.91.34 '
                            set -e; set -x;
                            rm -rf ${REPO_DIR};
                            git clone ${REPO_URL} ${REPO_DIR};
                            cd ${REPO_DIR};
                            docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                        '
                    """
                }
            }
        }

        stage('Push Docker Image to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${NEXUS_CREDENTIALS_ID}",
                    usernameVariable: 'DOCKER_USERNAME',
                    passwordVariable: 'DOCKER_PASSWORD'
                )]) {
                    sshagent(credentials: [dockerhost_ssh_key]) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ec2-user@15.206.91.34 '
                                docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${NEXUS_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG};
                                echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin ${NEXUS_REGISTRY};
                                docker push ${NEXUS_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                            '
                        """
                    }
                }
            }
        }

        stage('Export Kubeconfig and Deploy to Kubernetes') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-jenkins-creds',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export KOPS_STATE_STORE=s3://surya-k8-cluster-1
                        kops export kubecfg --name test.k8s.local
                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/service.yaml
                        kubectl rollout status deployment/my-httpd-site
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Build, SonarQube analysis, Docker push, and Kubernetes deployment completed successfully.'
        }
        failure {
            echo '❌ Build failed.'
        }
    }
}
