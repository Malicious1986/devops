def ECR_REGISTRY = "460589479898.dkr.ecr.eu-west-1.amazonaws.com"
def IMAGE_NAME   = "lesson-5-ecr"
def IMAGE_TAG    = "v1.0.${BUILD_NUMBER}"

def COMMIT_EMAIL = "jenkins@localhost"
def COMMIT_NAME  = "jenkins"

podTemplate(
  yaml: """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins-sa
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.16.0-debug
    imagePullPolicy: Always
    command: ['sleep']
    args: ['99d']
  - name: git
    image: alpine/git
    command: ['sleep']
    args: ['99d']
"""
) {
  node(POD_LABEL) {
    checkout scm

    stage('Build & Push Docker Image') {
      container('kaniko') {
        sh """
          /kaniko/executor \\
            --context \$(pwd)/django \\
            --dockerfile \$(pwd)/django/Dockerfile \\
            --destination=${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
        """
      }
    }

    stage('Update Chart Tag in Git') {
      container('git') {
        withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PAT')]) {
          sh """
            git clone https://\${GIT_USERNAME}:\${GIT_PAT}@github.com/Malicious1986/devops.git
            cd devops/charts/django-app

            sed -i "s/tag: .*/tag: ${IMAGE_TAG}/" values.yaml

            git config user.email "${COMMIT_EMAIL}"
            git config user.name "${COMMIT_NAME}"

            git add values.yaml
            git commit -m "Update image tag to ${IMAGE_TAG}"
            git push origin main
          """
        }
      }
    }
  }
}
