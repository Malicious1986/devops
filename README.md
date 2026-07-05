# DevOps Infrastructure as Code

This repository contains Terraform configurations for managing AWS infrastructure including VPC, ECR, S3 backend resources, and a Helm chart for deploying the Django application.

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
