pipeline {
  agent any

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
        sh "bash trivy-docker-image-scan.sh"
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
    // Step 4 - Kubernetes Deployment
    stage('Kubernetes Deployment - DEV') {
      steps {
        withKubeConfig([credentialsId: 'kubeconfig']) {
          sh "sed -i 's#replace#itinexperts/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
          sh "kubectl apply -f k8s_deployment_service.yaml"
        }
      }
    }
  }
}