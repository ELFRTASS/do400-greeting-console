pipeline{
    agent {
        kubernetes {
            inheritFrom 'nodejs'
            defaultContainer 'nodejs'
        }
    }
    stages{
        stage("Install dependencies"){
            steps{
                sh "npm ci"
            }
        }

        stage("Check Style"){
            steps{
                sh "npm run lint"
            }
        }

        stage("Test"){
            steps{
                sh "npm test"
            }
        }
        // install oc client
        stage('Install oc') {
            steps {
                sh '''
                  mkdir -p $HOME/bin
                  curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz \
                    | tar xz -C $HOME/bin oc
                  $HOME/bin/oc version --client
                '''
            }
        }

        // Add the Release stage here
        stage("Release"){
            steps{
                sh '''
                    oc project igalrq-jenkins 
                    oc start-build greeting-console --follow --wait'''
            }
        }
    }
}
