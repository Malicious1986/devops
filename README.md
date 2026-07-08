# DevOps Infrastructure as Code

Full CI/CD platform on AWS using Terraform, Helm, Jenkins, and Argo CD for automated building, publishing, and deploying of a Django application.

## Architecture Overview

```
Developer pushes code
        │
        ▼
┌───────────────┐
│    GitHub     │ ◄─────────────────────────────────┐
│  (source of   │                                   │
│    truth)     │                                   │
└───────┬───────┘                                   │
        │ trigger (manual / webhook)                │ git push (tag update)
        ▼                                           │
┌───────────────┐    push image    ┌─────────────┐  │
│    Jenkins    │ ───────────────► │  Amazon ECR │  │
│  (CI pipeline)│                  └─────────────┘  │
│               │ ──────────────────────────────────┘
│  Kaniko build │  update charts/django-app/values.yaml
└───────────────┘
        
┌───────────────┐    watch repo    ┌─────────────────────┐
│   Argo CD     │ ◄─────────────── │  charts/django-app/ │
│  (CD / GitOps)│                  │  values.yaml (tag)  │
└───────┬───────┘                  └─────────────────────┘
        │ sync
        ▼
┌───────────────────────────────────────────┐
│              Amazon EKS                   │
│  ┌─────────────┐   ┌───────────────────┐  │
│  │ Django pods │   │  Jenkins pod      │  │
│  │  (default)  │   │  (jenkins ns)     │  │
│  └─────────────┘   └───────────────────┘  │
│  ┌──────────────────────────────────────┐  │
│  │        Argo CD pods (argocd ns)      │  │
│  └──────────────────────────────────────┘  │
└───────────────────────────────────────────┘
```

## CI/CD Flow

1. **Jenkins** detects a trigger → runs `goit-django-docker` pipeline:
   - **Stage 1 — Build & Push**: Kaniko builds the Django Docker image and pushes it to ECR as `v1.0.<BUILD_NUMBER>`
   - **Stage 2 — Update Chart Tag**: clones the repo, updates `tag:` in `charts/django-app/values.yaml`, pushes the commit to `main`
2. **Argo CD** detects the new commit → automatically syncs the Helm chart → rolls out new Django pods with the updated image

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) v1.0+
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate IAM permissions
- [kubectl](https://kubernetes.io/docs/tasks/tools/) and [Helm](https://helm.sh/docs/intro/install/)

## Deploy the Full Stack

```bash
# 1. Clone the repository
git clone https://github.com/Malicious1986/devops.git
cd devops

# 2. Initialize Terraform (downloads providers and modules)
terraform init

# 3. Preview changes
terraform plan

# 4. Deploy everything (VPC, EKS, ECR, Jenkins, Argo CD)
terraform apply
```

This provisions:
- VPC with public/private subnets across 3 AZs
- EKS cluster with EBS CSI driver
- ECR repository for Docker images
- Jenkins via Helm (with JCasC, seed-job, Kubernetes agent)
- Argo CD via Helm (with Application and repo credentials)

## Access Services

After `terraform apply`, retrieve the service URLs:

```bash
# Jenkins
kubectl get svc -n jenkins jenkins

# Argo CD
kubectl get svc -n argocd argo-cd-argocd-server

# Django app
kubectl get svc -n default django-app-django
```

### Jenkins initial password
The admin password is set in `modules/jenkins/values.yaml` (`controller.admin.password`).

### Argo CD initial password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

## Trigger the CI/CD Pipeline

1. Go to Jenkins → `goit-django-docker` → **Build Now**
2. Jenkins builds the image, pushes to ECR, updates `charts/django-app/values.yaml` with the new tag
3. Argo CD detects the commit and deploys the new version automatically

## Project Structure

```
.
├── main.tf                  # Root module — wires all modules together
├── backend.tf               # S3 + DynamoDB remote state backend
├── outputs.tf               # Root-level outputs
├── providers.tf             # AWS, Kubernetes, Helm providers
├── versions.tf              # Provider version constraints
│
├── modules/
│   ├── vpc/                 # VPC, subnets, NAT gateways, routing
│   ├── eks/                 # EKS cluster, node group, OIDC, EBS CSI
│   ├── ecr/                 # ECR repository
│   ├── s3-backend/          # S3 bucket + DynamoDB for Terraform state
│   ├── jenkins/             # Jenkins Helm release + JCasC + IRSA
│   │   ├── jenkins.tf       # IAM role, service account, storage class
│   │   ├── values.yaml      # Jenkins configuration (plugins, JCasC, SA)
│   │   └── ...
│   └── argo_cd/             # Argo CD Helm release + app chart
│       ├── argo_cd.tf       # helm_release for argo-cd and argo-apps
│       ├── values.yaml      # Argo CD server config
│       ├── charts/          # Local Helm chart for Argo CD Applications
│       │   ├── Chart.yaml
│       │   ├── values.yaml  # Application + repository definitions
│       │   └── templates/
│       │       ├── application.yaml
│       │       └── repository.yaml
│       └── ...
│
├── charts/
│   └── django-app/          # Helm chart for the Django application
│       ├── values.yaml      # Image repo, tag, service type, HPA config
│       └── templates/       # Deployment, Service, ConfigMap, HPA
│
└── django/
    ├── Dockerfile           # Django app container image
    ├── Jenkinsfile          # CI/CD pipeline (build → push → update tag)
    └── app/                 # Django application source code
```

## Tear Down

```bash
terraform destroy
```

> **Note:** This deletes all AWS resources including the EKS cluster, ECR images, and load balancers.


## Getting Started

### Prerequisites
- [Terraform](https://www.terraform.io/downloads.html) installed (v1.0+)
- AWS credentials configured (via AWS CLI or environment variables)
- AWS IAM permissions for EC2, ECR, S3, and VPC resources

## Terraform Commands

### 1. Initialize Terraform
```bash
terraform init
```
Initializes the Terraform working directory, downloads required providers, and sets up the backend configuration.

### 2. Plan Infrastructure Changes
```bash
terraform plan
```
Creates an execution plan showing what resources will be created, modified, or destroyed. Review the plan before applying changes.

```bash
terraform plan -out=tfplan
```
Saves the plan to a file for later application, ensuring consistency between planning and applying.

### 3. Apply Infrastructure Changes
```bash
terraform apply
```
Applies the changes to create or update AWS resources. Terraform will prompt for confirmation before proceeding.

```bash
terraform apply tfplan
```
Applies a previously saved plan without prompting for confirmation.

### 4. Destroy Infrastructure
```bash
terraform destroy
```
Destroys all resources managed by Terraform. **Use with caution** - this will delete all infrastructure defined in your Terraform configuration.

## Docker, ECR, and Helm Deployment

The Django application Dockerfile lives in the `django/` folder. Build the image from there, push it to ECR, then deploy it with Helm.

### 1. Build the Docker Image
```bash
cd django
docker build -t django-app:latest .
```

### 2. Log In to ECR and Push the Image
Use the ECR repository URL from `terraform output repository_url`.

```bash
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com
docker tag django-app:latest <ecr-repository-url>:latest
docker push <ecr-repository-url>:latest
```

### 3. Deploy with Helm
Update `charts/django-app/values.yaml` if needed, then install or upgrade the release:

```bash
helm upgrade --install django-app ./charts/django-app -f ./charts/django-app/values.yaml
```

## Project Modules

### `modules/vpc/`
**VPC (Virtual Private Cloud) Module**

Creates a complete VPC infrastructure including:
- VPC with configurable CIDR block
- Public and private subnets across multiple availability zones
- Internet Gateway for public subnet connectivity
- Route tables and associations for traffic management

- NAT Gateways placed in public subnets to provide outbound internet access for private subnets

**Key Resources:**
- `aws_vpc.main` - Main VPC resource
- `aws_subnet.public` - Public subnets with auto-assigned public IPs
- `aws_subnet.private` - Private subnets for internal resources
- `aws_internet_gateway.igw` - Internet Gateway for public internet access

- `aws_eip.nat` - Elastic IPs allocated for NAT Gateways
- `aws_nat_gateway.nat` - NAT Gateways in public subnets used by private subnets for outbound access

### `modules/ecr/`
**ECR (Elastic Container Registry) Module**

Creates AWS Elastic Container Registry repositories for storing and managing Docker container images:
- Docker image storage and versioning
- Image scanning on push for vulnerability detection
- Tag mutability configuration
- Built-in image lifecycle policies support

**Key Resources:**
- `aws_ecr_repository.ecr` - ECR repository for storing container images
- Image scanning configuration for security compliance

### `modules/s3-backend/`
**S3 Backend Module**

Provides remote state storage infrastructure for Terraform:
- S3 bucket for storing Terraform state files
- Versioning enabled for state file history and recovery
- DynamoDB table for state locking to prevent concurrent modifications
- Bucket ownership controls for security

**Key Resources:**
- `aws_s3_bucket.terraform_state` - S3 bucket for Terraform state
- `aws_s3_bucket_versioning` - State versioning for backup and recovery
- `aws_s3_bucket_ownership_controls` - Ownership enforcement
- `aws_dynamodb_table` - State locking mechanism

## Usage Example

```bash
# 1. Initialize the Terraform environment
terraform init

# 2. Review what will be created
terraform plan -out=tfplan

# 3. Apply the infrastructure
terraform apply tfplan

# 4. (Optional) Destroy all resources
terraform destroy
```

## Project Structure

- `main.tf` - Main provider and resource configurations
- `backend.tf` - Backend configuration for remote state
- `outputs.tf` - Output values after resource creation
- `terraform.tfstate` - Current state file (local)
- `charts/django-app/` - Helm chart for the Django application
- `django/` - Django app, Dockerfile, and docker-compose setup
- `modules/` - Reusable Terraform modules
  - `vpc/` - VPC infrastructure
  - `ecr/` - Container registry
  - `s3-backend/` - Remote state backend

## Notes

- Store sensitive data (AWS keys, credentials) in environment variables or AWS credentials file
- Use `terraform plan` before applying to review changes
- Commit `tfplan` outputs for tracking infrastructure changes
- Keep `terraform.tfstate` files secure and backed up
