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
        dockerhost-ssh-key = 'docker-host-creds'
        NEXUS_REGISTRY = "13.232.158.95:5000"
        NEXUS_CREDENTIALS_ID = 'nexus-docker-creds'
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
                sshagent(credentials: [dockerhost-ssh-key]) {
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
        /*
        stage('Push Docker Image to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${NEXUS_CREDENTIALS_ID}",
                    usernameVariable: 'DOCKER_USERNAME',
                    passwordVariable: 'DOCKER_PASSWORD'
                )]) {
                    sshagent(credentials: [SSH_KEY_ID]) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ec2-user@65.0.4.10 '
                                docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${NEXUS_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG};
                                echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin ${NEXUS_REGISTRY};
                                docker push ${NEXUS_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                            '
                        """
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo "Deploying application to Kubernetes cluster"
                withCredentials([file(credentialsId: 'kubeconfig-cred', variable: 'KUBECONFIG')]) {
                    sh '''
                        export KUBECONFIG=$KUBECONFIG
                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/service.yaml
                        kubectl rollout status deployment/my-httpd-site
                    '''
                }
            }
        }
        */
    }

    /*
    post {
        success {
            echo '✅ Build, SonarQube analysis, Docker push, and Kubernetes deployment completed successfully.'
        }
        failure {
            echo '❌ Build failed.'
        }
    }
    */
}
