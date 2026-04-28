pipeline {
    agent any

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
                sh 'docker build -t react-app:latest .'
            }
        }
    }
}
