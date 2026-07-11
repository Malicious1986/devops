# DevOps Infrastructure as Code

Full CI/CD platform on AWS using Terraform, Helm, Jenkins, and Argo CD for automated building, publishing, and deploying a Django application.

---

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

---

## Project Structure

```
.
├── main.tf                  # Root module — wires all modules together
├── backend.tf               # S3 + DynamoDB remote state backend
├── outputs.tf               # Root-level outputs
├── providers.tf             # AWS, Kubernetes, Helm providers
├── versions.tf              # Provider version constraints
├── variables.tf             # Root input variables
│
├── modules/
│   ├── vpc/                 # VPC, subnets, Internet Gateway, routing
│   ├── eks/                 # EKS cluster, node group, OIDC, EBS CSI
│   ├── ecr/                 # ECR repository
│   ├── s3-backend/          # S3 bucket + DynamoDB for Terraform state
│   ├── rds/                 # RDS instance or Aurora cluster (use_aurora flag)
│   │   ├── rds.tf           # Standard aws_db_instance (use_aurora = false)
│   │   ├── aurora.tf        # Aurora cluster + writer + readers (use_aurora = true)
│   │   ├── shared.tf        # Shared subnet group and security group
│   │   ├── variables.tf     # All input variables with types and defaults
│   │   └── outputs.tf       # Endpoints, ports, security group ID
│   ├── jenkins/             # Jenkins Helm release + JCasC + IRSA
│   │   ├── jenkins.tf       # IAM role, service account, Helm release
│   │   └── values.yaml      # Jenkins configuration (plugins, JCasC, SA)
│   └── argo_cd/             # Argo CD Helm release + app chart
│       ├── argo_cd.tf       # helm_release for argo-cd and argo-apps
│       ├── values.yaml      # Argo CD server config
│       └── charts/          # Local Helm chart for Argo CD Applications
│           ├── Chart.yaml
│           ├── values.yaml  # Application + repository definitions
│           └── templates/
│               ├── application.yaml
│               └── repository.yaml
│
├── charts/
│   └── django-app/          # Helm chart for the Django application
│       ├── values.yaml      # Image repo, tag, service type, HPA config
│       └── templates/       # Deployment, Service, ConfigMap, HPA
│
├── django/
│   ├── Dockerfile           # Django app container image
│   └── app/                 # Django application source code
│
└── Jenkinsfile              # CI/CD pipeline (build → push → update tag)
```

---

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) v1.0+
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate IAM permissions
- [kubectl](https://kubernetes.io/docs/tasks/tools/) and [Helm](https://helm.sh/docs/intro/install/)

---

## Deploy the Full Stack

```bash
# 1. Clone the repository
git clone https://github.com/Malicious1986/devops.git
cd devops

# 2. Set required environment variables (never commit these)
export TF_VAR_jenkins_admin_password="your-jenkins-password"
export TF_VAR_github_pat="your-github-pat"
export TF_VAR_db_name="myapp"
export TF_VAR_db_password="your-db-password"

# Optional: deploy Aurora instead of standard RDS (default: false)
# export TF_VAR_use_aurora=true

# 3. Initialize Terraform
terraform init

# 4. Preview changes
terraform plan

# 5. Deploy everything
terraform apply
```

This provisions:
- VPC with public/private subnets across 3 AZs
- EKS cluster with EBS CSI driver
- ECR repository for Docker images
- RDS PostgreSQL instance (or Aurora cluster if `TF_VAR_use_aurora=true`)
- Jenkins via Helm (JCasC, seed-job, Kubernetes agent)
- Argo CD via Helm (Application and repo credentials)

---

## Terraform Commands

| Command | Description |
|---------|-------------|
| `terraform init` | Download providers and modules |
| `terraform plan` | Preview changes without applying |
| `terraform plan -out=tfplan` | Save plan to file |
| `terraform apply` | Apply changes (prompts for confirmation) |
| `terraform apply tfplan` | Apply a saved plan without prompting |
| `terraform destroy` | **Destroy all resources** (irreversible) |

---

## Access Services

After `terraform apply`:

```bash
# Jenkins
kubectl get svc -n jenkins jenkins

# Argo CD
kubectl get svc -n argocd argo-cd-argocd-server

# Django app
kubectl get svc -n default django-app-django

# Argo CD initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

The Jenkins admin password is set via `TF_VAR_jenkins_admin_password`.

---

## CI/CD Flow

1. Go to Jenkins → `goit-django-docker` → **Build Now**
2. **Stage 1 — Build & Push**: Kaniko builds the Django image and pushes it to ECR as `v1.0.<BUILD_NUMBER>`
3. **Stage 2 — Update Chart**: Jenkins updates `tag:` in `charts/django-app/values.yaml` and pushes to `main`
4. **Argo CD** detects the commit and automatically syncs → new Django pods roll out

---

## Modules Reference

### `modules/vpc/`
Creates a complete VPC: CIDR-configurable VPC, public/private subnets across multiple AZs, Internet Gateway, NAT Gateways, and route tables.

### `modules/eks/`
Creates an EKS cluster with a managed node group, OIDC provider for IRSA, and installs the EBS CSI driver for persistent volume support.

### `modules/ecr/`
Creates an ECR repository with configurable image scanning on push and tag mutability.

### `modules/s3-backend/`
Creates an S3 bucket (versioning enabled) and DynamoDB table for Terraform remote state storage and locking.

### `modules/rds/`
Flexible module for deploying a relational database. Supports two modes via `use_aurora`:

- `use_aurora = false` → standard `aws_db_instance` (PostgreSQL / MySQL)
- `use_aurora = true` → Aurora cluster with writer + reader replicas

In both cases creates: DB subnet group, security group, and parameter group.

**Usage — Standard RDS:**
```hcl
module "rds" {
  source = "./modules/rds"

  name                       = "myapp-db"
  use_aurora                 = false
  engine                     = "postgres"
  engine_version             = "17.5"
  parameter_group_family_rds = "postgres17"
  instance_class             = "db.t4g.micro"
  allocated_storage          = 20
  db_name                    = var.db_name
  username                   = "postgres"
  password                   = var.db_password
  subnet_private_ids         = module.vpc.private_subnets
  subnet_public_ids          = module.vpc.public_subnets
  publicly_accessible        = false
  vpc_id                     = module.vpc.vpc_id
  multi_az                   = false
  backup_retention_period    = 0
  parameters = {
    max_connections            = "200"
    log_statement              = "all"
    work_mem                   = "4096"
    log_min_duration_statement = "500"
  }
  tags = { Environment = "dev", Project = "myapp" }
}
```

**Usage — Aurora:**
```hcl
module "rds" {
  source = "./modules/rds"

  name                          = "myapp-db"
  use_aurora                    = true
  aurora_replica_count          = 1
  engine_cluster                = "aurora-postgresql"
  engine_version_cluster        = "15.3"
  parameter_group_family_aurora = "aurora-postgresql15"
  instance_class                = "db.t3.medium"
  db_name                       = var.db_name
  username                      = "postgres"
  password                      = var.db_password
  subnet_private_ids            = module.vpc.private_subnets
  subnet_public_ids             = module.vpc.public_subnets
  publicly_accessible           = false
  vpc_id                        = module.vpc.vpc_id
  backup_retention_period       = 7
  tags = { Environment = "prod", Project = "myapp" }
}
```

**RDS Variables:**

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `name` | `string` | — | Unique name for the instance or cluster |
| `use_aurora` | `bool` | `false` | `true` = Aurora cluster, `false` = standard RDS |
| `engine` | `string` | `"postgres"` | DB engine for standard RDS |
| `engine_version` | `string` | `"17.5"` | Engine version for standard RDS |
| `parameter_group_family_rds` | `string` | `"postgres17"` | Parameter group family for standard RDS |
| `engine_cluster` | `string` | `"aurora-postgresql"` | DB engine for Aurora |
| `engine_version_cluster` | `string` | `"15.3"` | Engine version for Aurora |
| `parameter_group_family_aurora` | `string` | `"aurora-postgresql15"` | Parameter group family for Aurora |
| `aurora_replica_count` | `number` | `1` | Number of Aurora reader replicas |
| `instance_class` | `string` | `"db.t4g.micro"` | DB instance class |
| `allocated_storage` | `number` | `20` | Storage in GB (standard RDS only) |
| `db_name` | `string` | — | Initial database name |
| `username` | `string` | — | Master username |
| `password` | `string` | — | Master password (sensitive) |
| `vpc_id` | `string` | — | VPC ID |
| `subnet_private_ids` | `list(string)` | — | Private subnet IDs for subnet group |
| `subnet_public_ids` | `list(string)` | — | Public subnet IDs (used if `publicly_accessible = true`) |
| `publicly_accessible` | `bool` | `false` | Expose DB over the internet |
| `multi_az` | `bool` | `false` | Multi-AZ deployment (not available on free tier) |
| `backup_retention_period` | `number` | `0` | Days to keep automated backups (0 = disabled) |
| `parameters` | `map(string)` | `{}` | Parameter group key/value settings |
| `tags` | `map(string)` | `{}` | Tags for all resources |

**How to change DB type:**
```hcl
# Switch to MySQL
engine = "mysql"
engine_version = "8.0"
parameter_group_family_rds = "mysql8.0"

# Change instance class
instance_class = "db.t3.medium"   # more resources
instance_class = "db.t4g.micro"   # free tier

# Switch to Aurora MySQL
use_aurora = true
engine_cluster = "aurora-mysql"
engine_version_cluster = "8.0"
parameter_group_family_aurora = "aurora-mysql8.0"
```

### `modules/jenkins/`
Deploys Jenkins via Helm with JCasC (Jenkins Configuration as Code), a seed job for pipeline auto-discovery, IRSA for ECR access, and a persistent volume for the Jenkins home directory.

### `modules/argo_cd/`
Deploys Argo CD via Helm and a local Helm chart that registers the GitHub repository and creates the `django-app` Application resource for GitOps-based deployments.

---

## Tear Down

```bash
terraform destroy
```

> **Warning:** This permanently deletes all AWS resources including the EKS cluster, RDS database, ECR images, and load balancers.

---

## Notes

- Never commit `terraform.tfvars` or files containing secrets
- Always run `terraform plan` before `terraform apply`
- `terraform.tfstate` contains sensitive data — keep it secure and use remote state in production
