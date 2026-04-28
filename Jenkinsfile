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

        stage('Build') {
            steps {
                dir('react-app') {
                    sh 'npm run build'
                }
            }
        }
    }
}