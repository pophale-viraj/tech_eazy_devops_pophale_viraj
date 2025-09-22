pipeline {
    agent any

    tools {
            maven 'mvn_3.9.11'  // Make sure this Maven tool is defined in Jenkins global tools
        }

    environment {
        EC2_HOST = "3.111.170.112"                 // replace with your EC2 public IP
        EC2_USER = "ubuntu"
        SSH_KEY_ID = "ec2-ssh"            // Jenkins credential ID
        APP_DIR = "/home/ubuntu/app"      // deployment directory on EC2
        JAR_NAME = "hellomvc-0.0.1-SNAPSHOT.jar"
    }

    stages {
        /* stage('Checkout') {
            steps {
                git branch: 'master', url: 'https://github.com/pophale-viraj/tech_eazy_devops_pophale_viraj.git'
            }
        } */

        stage('Code Compilation') {
            steps {
                echo 'Starting Code Compilation...'
                sh 'mvn clean compile'
                echo 'Code Compilation Completed Successfully!'
            }
        }

        stage('Code QA Execution') {
            steps {
                echo 'Running JUnit Test Cases...'
                sh 'mvn clean test'
                echo 'JUnit Test Cases Completed Successfully!'
            }
        }

        stage('Code Package') {
            steps {
                echo 'Creating WAR Artifact...'
                sh 'mvn clean package'
                echo 'WAR Artifact Created Successfully!'
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent (credentials: [SSH_KEY_ID]) {
                    // Create app directory if not exists
                    sh """
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} 'mkdir -p ${APP_DIR}'
                    """

                    // Copy jar to EC2
                    sh """
                        scp -o StrictHostKeyChecking=no target/${JAR_NAME} ${EC2_USER}@${EC2_HOST}:${APP_DIR}/
                    """

                    // Restart app on EC2
                    sh """
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                            pkill -f ${JAR_NAME} || true &&
                            nohup java -jar ${APP_DIR}/${JAR_NAME} > ${APP_DIR}/app.log 2>&1 &
                        '
                    """
                }
            }
        }
    }
}
