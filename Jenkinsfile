pipeline {
  agent any

  environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "itinexperts/numeric-app:${GIT_COMMIT}"
    applicationURL = "http://localhost/"
    applicationURI = "/increment/99"
  }

  stages {
    // Step 1 - Build Artifact
    stage('Build Artifact - Maven') {
      steps {
        sh "mvn clean package -DskipTests=true"
        archive 'target/*.jar'
      }
    }
    // Step 2 - Unit Test
    stage('Unit Tests- Junit & Jacoco') {
      steps {
        sh "mvn test"
      }
      post {
        always {
          junit 'target/surefire-reports/*.xml'
          jacoco execPattern: 'target/jacoco.exec'
        }
      }
    }
    // Step 5 - Mutation Tests
    stage('Mutation Tests - PIT') {
      steps {
        sh "mvn org.pitest:pitest-maven:mutationCoverage"
      }
      post {
        always {
          pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
        }
      }
    }
    // Step 6 - SonarQube SAST
    stage('SonarQube - SAST') {
      steps {
        withSonarQubeEnv('SonarQube') {
          sh "mvn clean verify sonar:sonar -Dsonar.projectKey=devsecops-apps  -Dsonar.host.url=http://localhost:9000 -Dsonar.login=sqp_5c3e3d07e6abe2e0861326c8ec9e9f50bb094f55"
        }
        timeout(time: 2, unit: 'MINUTES') {
         script {
           waitForQualityGate abortPipeline: true
         }
        }
      }
    }
    // Step 7 - Dependency Check
    stage('Dependency Check') {
      steps {
        sh "mvn dependency-check:check"
      }
      post {
        always {
          dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
        }
      }
    }
    // Step 8 - Trivy Scan
    stage('Vulnerability Scan - Docker') {
      steps {
        parallel(
          "Trivy Scan":{
            sh "bash trivy-docker-image-scan.sh"
          }, // Step 9 - Add Conftest
          "OPA Conftest":{
            sh "docker run --rm -v ${pwd}/workspace/devsecops-lab-1:/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile"
          }
        )
      }
    }
    // Step 3 - Build and Push
    stage('Docker Build and Push') {
      steps {
        withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
          sh 'printenv'
          sh 'sudo docker build -t itinexperts/numeric-app:""$GIT_COMMIT"" .'
          sh 'docker push itinexperts/numeric-app:""$GIT_COMMIT""'
        }
      }
    }
    // Step 10 - Kubernetes Security
    stage('Vulnerability Scan - Kubernetes') {
      steps {
        parallel(
          "OPA Scan": {
            sh "docker run --rm -v ${pwd}/workspace/devsecops-lab-1:/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml"
          },
          "Kubesec Scan:": {
            sh "bash kubesec-scan.sh"
          }//,
          //"Trivy Scan": {
          //  sh "bash trivy-k8s-scan.sh"
          //}
        )
      }
    }

    // Step 4 - Kubernetes Deployment
    stage('Kubernetes Deployment - DEV') {
      steps {
        parallel(
          "Deployment": {
            withKubeConfig([credentialsId: 'kubeconfig']) {
              sh "bash k8s-deployment.sh"
              //sh "sed -i 's#replace#itinexperts/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
              //sh "kubectl apply -f k8s_deployment_service.yaml"
            }
          },
          "Rollout Status": {
            withKubeConfig([credentialsId: 'kubeconfig']) {
              sh "bash k8s-deployment-rollout-status.sh"
            }
          }
        )
      }
    }
    // Step 11 - DAST Scan
    stage('OWASP ZAP - DAST') {
      steps {
        withKubeConfig([credentialsId: 'kubeconfig']) {
          sh 'bash zap.sh'
        }
      }
      post {
        always {
          publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap_report.html', reportName: 'OWASP ZAP HTML Report', reportTitles: 'OWASP ZAP HTML Report'])
        }
      }
    }
  }
}