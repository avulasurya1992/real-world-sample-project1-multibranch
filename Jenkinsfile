pipeline {
    agent any

    environment {
        SONARQUBE_SCANNER = 'sonar-scanner'
        SONARQUBE_SERVER  = 'SonarQubeServer'
        DOCKER_HOST = "ssh://ec2-user@65.0.4.10"
        IMAGE_NAME = "my-httpd-site"
        IMAGE_TAG = "latest"
        REPO_URL = "https://github.com/avulasurya1992/real-world-sample-project1-multibranch.git"
        REPO_DIR = "real-world-sample-project1-multibranch"
        SSH_KEY_ID = 'docker-host-creds'
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
                    withCredentials([string(credentialsId: 'SONAR_TOKEN_ID', variable: 'SONAR_TOKEN')]) {
                        sh """
                            ${tool SONARQUBE_SCANNER}/bin/sonar-scanner \\
                            -Dsonar.projectKey=sample-project1 \\
                            -Dsonar.sources=. \\
                            -Dsonar.projectName=sample-project1 \\
                            -Dsonar.exclusions=**/Dockerfile \\
                            -Dsonar.host.url=http://13.235.42.250:9000 \\
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
                script {
                    echo "Building Docker image on remote Docker host"

                    sshagent(credentials: [SSH_KEY_ID]) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ec2-user@65.0.4.10 '
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
        }

        stage('Push Docker Image to Nexus') {
            steps {
                script {
                    echo "Pushing Docker image to Nexus registry from remote host"

                    sshagent(credentials: [SSH_KEY_ID]) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ec2-user@65.0.4.10 '
                                docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${NEXUS_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG};
                                echo "Logging into Nexus registry";
                                docker login -u \$(echo $DOCKER_USERNAME) -p \$(echo $DOCKER_PASSWORD) ${NEXUS_REGISTRY};
                                docker push ${NEXUS_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                            '
                        """
                    }
                }
                environment {
                    DOCKER_USERNAME = credentials("${NEXUS_CREDENTIALS_ID}").username
                    DOCKER_PASSWORD = credentials("${NEXUS_CREDENTIALS_ID}").password
                }
            }
        }

        stage('Run Docker Container') {
            steps {
                script {
                    echo "Running Docker container on remote Docker host"

                    sshagent(credentials: [SSH_KEY_ID]) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ec2-user@65.0.4.10 '
                                docker run -dt -p 8080:80 ${IMAGE_NAME}:${IMAGE_TAG}
                            '
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo '✅ Build, SonarQube analysis, and Docker push completed successfully.'
        }
        failure {
            echo '❌ Build failed.'
        }
    }
}
