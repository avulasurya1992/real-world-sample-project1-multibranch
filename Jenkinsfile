pipeline {
    agent any

    environment {
        SONARQUBE_SCANNER = 'sonar-scanner'
        SONARQUBE_SERVER  = 'SonarQubeServer'
        DOCKER_HOST = "ssh://ec2-user@3.108.42.154" // SSH connection to the Docker host
        IMAGE_NAME = "my-httpd-site:latest"
        REPO_URL = "https://github.com/avulasurya1992/real-world-sample-project1-multibranch.git"
        REPO_DIR = "real-world-sample-project1-multibranch" // The directory where repo will be cloned on the Docker host
        SSH_KEY_ID = 'docker-host-creds' // The credentials ID you created
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
                            -Dsonar.host.url=http://65.1.109.36:9000 \\
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

                    // Run the Docker build command on the remote Docker server via SSH using Jenkins credentials
                    sh """
                        ssh -i ${JENKINS_HOME}/.ssh/${SSH_KEY_ID} -o StrictHostKeyChecking=no ec2-user@3.108.42.154 \\
                        'git clone ${REPO_URL} ${REPO_DIR} || (cd ${REPO_DIR} && git pull) && cd ${REPO_DIR} && docker build -t ${IMAGE_NAME} .'
                    """
                }
            }
        }

        stage('Run Docker Container') {
            steps {
                script {
                    echo "Running Docker container on remote Docker host"

                    // Run the Docker container on the remote Docker server via SSH
                    sh """
                        ssh -i ${JENKINS_HOME}/.ssh/${SSH_KEY_ID} -o StrictHostKeyChecking=no ec2-user@3.108.42.154 \\
                        'docker run -d -p 8080:80 ${IMAGE_NAME}'
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Build and SonarQube analysis completed successfully.'
        }
        failure {
            echo '❌ Build failed.'
        }
    }
}
