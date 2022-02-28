pipeline {
    agent {
        label 'Slave1'
    }

    tools {
        // Install the Maven version configured as "M3" and add it to the path.
        maven "mnc3"
    }

    environment {
        IMAGE = sh script: 'mvn help:evaluate -Dexpression=project.artifactid -q -DforceStdout', returnStdout: true
        VERSION = sh script: 'mvn help:evaluate -Dexpression=project.version -q -DforceStdout', returnStdout: true
        MAVEN_GLOBAL_SETTINGS
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
                sh "mvn package -Pdocker"
            }
        }
        stage('Run docker container') {
            steps {
                sh "docker run -d -p 8080:8080 --name pandaapp ${IMAGE}:${VERSION}"
            }
        }
        stage('Test') {
            steps {
                // Run Maven on a Unix agent.
                sh "mvn test -Pselenium"
            }
        }
        stage('Deploy to Artifactory') {
            steps {
                configFileProvider([configFile(fileId: '0dbda896-db8e-4aae-b00a-930bdf5ecac2', variable: 'MAVEN_GLOBAL_SETTINGS')]) {
                    sh "mvn -gs $MAVEN_GLOBAL_SETTINGS deploy -Dmaven.test.skip=true -e"
                }
            }
        }
        post {
            always {
                sh "docker stop pandaapp"
            }
        }
    }
}