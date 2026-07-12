data "aws_eks_cluster" "eks" {
  name       = module.eks.eks_cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks" {
  name       = module.eks.eks_cluster_name
  depends_on = [module.eks]
}

module "s3_backend" {
    source = "./modules/s3-backend"

    bucket_name = "terraform-state-bucket-6590"

    table_name = "terraform-locks"
} 

module "vpc" {
    source = "./modules/vpc"
    cluster_name        = "eks-cluster-demo"
    vpc_cidr_block = "10.0.0.0/16"
    public_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]        
    private_subnets     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]         
    availability_zones  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]           
    vpc_name = "vpc"
}

module "ecr" {
    source = "./modules/ecr"
    ecr_name = "lesson-5-ecr"
    scan_on_push = true
    image_tag_mutability = "MUTABLE"
}

module "eks" {
  source          = "./modules/eks"          
  cluster_name    = "eks-cluster-demo"            # Назва кластера
  subnet_ids      = module.vpc.private_subnets     # ID підмереж
  instance_type   = "t3.small"                    # Тип інстансів
  desired_size    = 3                             # Бажана кількість нодів
  max_size        = 3                             # Максимальна кількість нодів
  min_size        = 2                             # Мінімальна кількість нодів
}

module "rds" {
  source = "./modules/rds"

  name                       = "djangoapp-db"
  use_aurora                 = var.use_aurora
  aurora_replica_count      = 2

    # --- Aurora-only ---
  engine_cluster             = "aurora-postgresql"
  engine_version_cluster     = "15.3"
  parameter_group_family_aurora = "aurora-postgresql15"

  # --- RDS-only ---
  engine                     = "postgres"
  engine_version             = "17.5"
  parameter_group_family_rds = "postgres17"

  # Common
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
  backup_retention_period    = 1
  parameters = {
    max_connections              = "200"
    log_min_duration_statement   = "500"
    log_statement                = "all"
    work_mem                     = "4096"
  }

  tags = {
    Environment = "dev"
    Project     = "djangoapp"
  }
} 


resource "kubernetes_persistent_volume_claim_v1" "jenkins_home" {
  metadata {
    name      = "jenkins"
    namespace = "jenkins"
    annotations = {
      "meta.helm.sh/release-name"      = "jenkins"
      "meta.helm.sh/release-namespace" = "jenkins"
    }
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "gp3"
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }

  wait_until_bound = false
}

module "jenkins" {
  source                 = "./modules/jenkins"
  cluster_name           = module.eks.eks_cluster_name
  kubeconfig             = pathexpand("~/.kube/config")
  oidc_provider_arn      = module.eks.oidc_provider_arn
  oidc_provider_url      = module.eks.oidc_provider_url
  jenkins_admin_password = var.jenkins_admin_password
  depends_on             = [module.eks, kubernetes_storage_class_v1.gp3, kubernetes_persistent_volume_claim_v1.jenkins_home]
}

module "argo_cd" {
  source        = "./modules/argo_cd"
  namespace     = "argocd"
  chart_version = "5.46.4"
  github_pat    = var.github_pat
  depends_on    = [module.eks]
}

resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
  }

  storage_provisioner = "ebs.csi.aws.com"

  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type   = "gp3"
    fsType  = "ext4"
    encrypted = "true"
  }
}