pipeline {
    agent { label 'docker' } 

    environment {
        JFROG_URL = credentials('jfrog-url') 
        JFROG_DOCKER_REPO = credentials('jfrog-docker-repo')
        JFROG_USER = credentials('jfrog-user')
        SONAR_PROJECT_KEY = credentials('sonar-project-key')
        SONAR_ORG = credentials('sonar-org')
        SONAR_HOST_URL = credentials('sonar-host-url')
        SONAR_TOKEN = credentials('sonar-credentials')
        JFROG_TOKEN = credentials('jfrog-credentials')
        IMAGE_TAG = "v1.0.${env.BUILD_NUMBER}"
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('2. Trivy FS (SCA Scan)'){
            steps{
                script {
                    // Set exit-code to 1: If HIGH/CRITICAL vulnerabilities are found, fail the Pipeline immediately (Security Gate)
                    sh "trivy fs --severity HIGH,CRITICAL --exit-code 1 ."
                }
            }
        }
        stage('3. SonarQube Code Analysis') {
            environment {
                SCANNER_HOME = tool 'SonarScanner'
            }
            steps {
                script {
                    echo "Scanning source code with SonarCloud..."
                    sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                        -Dsonar.organization=${SONAR_ORG} \
                        -Dsonar.sources=./backend,./frontend \
                        -Dsonar.host.url=${SONAR_HOST_URL} \
                        -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }

/*
        stage('3.5. SonarQube Quality Gate') {
            steps {
                script {
                    // Wait for SonarQube analysis results. If Quality Gate fails, abort the Pipeline.
                    timeout(time: 5, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }
*/

        stage('3. Build Docker Images') {
            steps {
                script {
                    echo "Building Backend and Frontend Docker Images..."
                    sh "docker build -t ${JFROG_DOCKER_REPO}/backend:${IMAGE_TAG} ./backend"
                    sh "docker build -t ${JFROG_DOCKER_REPO}/frontend:${IMAGE_TAG} ./frontend"
                }
            }
        }

        stage('4. Trivy Image Vulnerability Scan') {
            steps {
                script {
                    echo "Scanning Docker Images for vulnerabilities..."
                    // Set exit-code to 1 to block vulnerable Images from being pushed to JFrog
                    // We use --vuln-type os because Application packages are already scanned by 'trivy fs' in Stage 2
                    sh "trivy image --vuln-type os --severity HIGH,CRITICAL --exit-code 1 ${JFROG_DOCKER_REPO}/backend:${IMAGE_TAG}"
                    sh "trivy image --vuln-type os --severity HIGH,CRITICAL --exit-code 1 ${JFROG_DOCKER_REPO}/frontend:${IMAGE_TAG}"
                }
            }
        }

        stage('5. Push to JFrog (Main Branch Only)') {
            when {
                anyOf {
                    branch 'main'
                    branch 'feature-build-ci/cd'
                }
            }
            steps {
                script {
                    echo "Logging into JFrog and pushing Images..."
                    sh "echo ${JFROG_TOKEN} | docker login ${JFROG_URL} -u ${JFROG_USER} --password-stdin"
                    sh "docker push ${JFROG_DOCKER_REPO}/backend:${IMAGE_TAG}"
                    sh "docker push ${JFROG_DOCKER_REPO}/frontend:${IMAGE_TAG}"
                }
            }
        }
    }

    post {
        always {
            // Clean up Docker images on Agent regardless of Pipeline success or failure
            sh "docker rmi ${JFROG_DOCKER_REPO}/backend:${IMAGE_TAG} || true"
            sh "docker rmi ${JFROG_DOCKER_REPO}/frontend:${IMAGE_TAG} || true"
        }
        success {
            echo "✅ PIPELINE SUCCESSFUL! Images are ready to be deployed."
            script {
                def authorEmail = sh(script: "git --no-pager show -s --format='%ae'", returnStdout: true).trim()
                mail to: authorEmail,
                     subject: "✅ SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                     body: "Great news! The pipeline completed successfully.\nCheck console output at: ${env.BUILD_URL}"
            }
        }
        failure {
            echo "❌ PIPELINE FAILED! Please check the logs of the security tools (Trivy/Sonar)."
            script {
                def authorEmail = sh(script: "git --no-pager show -s --format='%ae'", returnStdout: true).trim()
                mail to: authorEmail,
                     subject: "❌ FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                     body: "The pipeline failed. Please check the logs of the security tools (Trivy/Sonar).\nCheck console output at: ${env.BUILD_URL}"
            }
        }
    }
}
