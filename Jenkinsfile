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

        stage('Test') {
            steps {
                dir('react-app') {
                    sh 'npm test'
                }
            }
        }
    }
}