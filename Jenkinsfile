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

        stage('2. OWASP Dependency Check'){
            steps{
                script{
                    dependencyCheck additionalArguments: '--scan ./backend --scan ./frontend --format HTML --format XML --noupdate', odcInstallation: 'DP-Check'
                    dependencyCheckPublisher pattern: 'dependency-check-report.xml'
                }
            }
        }
        stage('3. SonarQube Code Analysis') {
            steps {
                script {
                    echo "Đang quét mã nguồn bằng SonarCloud..."
                    sh """
                        sonar-scanner \
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                        -Dsonar.organization=${SONAR_ORG} \
                        -Dsonar.sources=./backend,./frontend \
                        -Dsonar.host.url=${SONAR_HOST_URL} \
                        -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }

        stage('3. Build Docker Images') {
            steps {
                script {
                    echo "Đóng gói Backend và Frontend..."
                    sh "docker build -t ${JFROG_DOCKER_REPO}/backend:${IMAGE_TAG} ./backend"
                    sh "docker build -t ${JFROG_DOCKER_REPO}/frontend:${IMAGE_TAG} ./frontend"
                }
            }
        }

        stage('4. Trivy Image Vulnerability Scan') {
            steps {
                script {
                    echo "Quét lỗi bảo mật Docker Image..."
                    sh "trivy image --severity HIGH,CRITICAL --exit-code 0 ${JFROG_DOCKER_REPO}/backend:${IMAGE_TAG}"
                    sh "trivy image --severity HIGH,CRITICAL --exit-code 0 ${JFROG_DOCKER_REPO}/frontend:${IMAGE_TAG}"
                }
            }
        }

        stage('5. Push to JFrog (Chỉ chạy trên nhánh Main)') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "Đăng nhập JFrog và đẩy Image..."
                    sh "echo ${JFROG_TOKEN} | docker login ${JFROG_URL} -u ${JFROG_USER} --password-stdin"
                    
                    sh "docker push ${JFROG_DOCKER_REPO}/backend:${IMAGE_TAG}"
                    sh "docker push ${JFROG_DOCKER_REPO}/frontend:${IMAGE_TAG}"
                }
            }
        }
    }

    post {
        always {
            // Dọn dẹp rác trên Agent
            sh "docker rmi ${JFROG_DOCKER_REPO}/backend:${IMAGE_TAG} || true"
            sh "docker rmi ${JFROG_DOCKER_REPO}/frontend:${IMAGE_TAG} || true"
        }
    }
}
