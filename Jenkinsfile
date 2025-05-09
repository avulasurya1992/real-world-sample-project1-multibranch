pipeline {
    agent any

  
    environment {
        SONARQUBE_SCANNER = 'sonar-scanner'
        SONARQUBE_SERVER  = 'SonarQubeServer'
    }

    stages {
        stage('Checkout') {
            steps {
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
                            ${tool SONARQUBE_SCANNER}/bin/sonar-scanner \
                            -Dsonar.projectKey=sample-project1 \
                            -Dsonar.sources=. \
                            -Dsonar.projectName=sample-project1 \
                            -Dsonar.host.url=http://65.1.109.36:9000 \
                            -Dsonar.login=$SONAR_TOKEN
                        """
                    }
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
