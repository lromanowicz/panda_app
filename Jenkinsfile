pipeline {
    agent {
        label 'Slave1'
    }

    tools {
        // Install the Maven version configured as "M3" and add it to the path.
        maven "mnc3"
        terraform
    }

    environment {
        IMAGE = sh script: 'mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout', returnStdout: true
        VERSION = sh script: 'mvn help:evaluate -Dexpression=project.version -q -DforceStdout', returnStdout: true
        ANSIBLE = tool name: 'Ansible', type: 'com.cloudbees.jenkins.plugins.customtools.CustomTool'
    }

    stages {
        stage('Clear running apps') {
            steps {
                // Get some code from a GitHub repository
                sh 'docker rm -f pandaapp || true'
            }
        }
        stage('Build') {
            steps {
                // Run Maven on a Unix agent.
                sh "mvn -Dmaven.test.failure.ignore=true clean install"
            }
        }
        stage('Build docker image') {
            steps {
                sh "mvn package -Pdocker -Dmaven.test.skip=true"
            }
        }
        stage('Run docker container') {
            steps {
                sh "docker run -d -p 8080:8080 --name pandaapp ${IMAGE}:${VERSION}"
            }
        }
        // stage('Test') {
        //     steps {
        //         // Run Maven on a Unix agent.
        //         sh "mvn test -Pselenium"
        //     }
        // }
        stage('Deploy to Artifactory') {
            steps {
                configFileProvider([configFile(fileId: '0dbda896-db8e-4aae-b00a-930bdf5ecac2', variable: 'MAVEN_GLOBAL_SETTINGS')]) {
                    sh "mvn -gs $MAVEN_GLOBAL_SETTINGS deploy -Dmaven.test.skip=true -e"
                }
            }
        }
        stage('Run Terraform') {
            steps {
                withCredentials([file(credentialsId: 'panda', variable: 'terraformpanda')]) {
                    sh "cp \$terraformpanda ..panda.pem"
                }

                dir('infrastructure/terraform') { 
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS_CREDS']]) {
                        sh 'terraform init && terraform apply -auto-approve -var-file panda.tfvars'
                    }
                }
            }
        }
        stage('Copy Ansible role') {
            steps {
                sh 'cp -r infrastructure/ansible/panda/ /etc/ansible/roles/'
                sh 'sleep 180'
            }
        }
        stage('Run Ansible') {
            steps {
                dir('infrastructure/ansible') { 
                    sh 'chmod 600 ../panda.pem'
                    sh 'ansible-playbook -i ./inventory playbook.yml -e ansible_python_interpreter=/usr/bin/python3'
                }
            }
        }
        stage('Remove environment') {
            steps {
                input 'Remove environment'
                dir('infrastructure/terraform') { 
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS_CREDS']]) {
                        sh 'terraform destroy -auto-approve -var-file panda.tfvars'
                    }
                }
            }
        }

    }
    post {
        success {
            sh 'docker stop pandaapp'
            deleteDir()
        }
        failure {
            dir('infrastructure/terraform') { 
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS_CREDS']]) {
                    sh 'terraform destroy -auto-approve -var-file panda.tfvars'
                }
            }
            sh 'docker stop pandaapp'
            deleteDir()
        }
    }
}