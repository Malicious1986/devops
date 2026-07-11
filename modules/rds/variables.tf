variable "name" {
  description = "Unique name for the RDS instance or Aurora cluster"
  type        = string
}

variable "use_aurora" {
  description = "If true, an Aurora cluster is created; if false, a standard RDS instance"
  type        = bool
  default     = false
}

# --- RDS-only ---

variable "engine" {
  description = "Database engine for standard RDS (postgres, mysql, etc.)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version for the standard RDS instance"
  type        = string
  default     = "17.5"
}

variable "parameter_group_family_rds" {
  description = "Parameter group family for standard RDS (e.g. postgres17)"
  type        = string
  default     = "postgres17"
}

# --- Aurora-only ---

variable "engine_cluster" {
  description = "Database engine for the Aurora cluster (aurora-postgresql or aurora-mysql)"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version_cluster" {
  description = "Engine version for the Aurora cluster"
  type        = string
  default     = "15.3"
}

variable "parameter_group_family_aurora" {
  description = "Parameter group family for Aurora (e.g. aurora-postgresql15)"
  type        = string
  default     = "aurora-postgresql15"
}

variable "aurora_replica_count" {
  description = "Number of reader replicas in the Aurora cluster"
  type        = number
  default     = 1
}

# --- Common ---

variable "instance_class" {
  description = "DB instance class (e.g. db.t4g.micro, db.t3.medium)"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB (standard RDS only)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the initial database"
  type        = string
}

variable "username" {
  description = "Master username for the database"
  type        = string
}

variable "password" {
  description = "Master password for the database (sensitive)"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "ID of the VPC where the database will be deployed"
  type        = string
}

variable "subnet_private_ids" {
  description = "List of private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "subnet_public_ids" {
  description = "List of public subnet IDs (used when publicly_accessible = true)"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Whether the database is publicly accessible over the internet"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for standard RDS (not supported on free tier)"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups (0 = disabled; free tier only supports 0)"
  type        = number
  default     = 0
}

variable "parameters" {
  description = "Map of parameter group settings (key = parameter name, value = string value)"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to all resources in the module"
  type        = map(string)
  default     = {}
}
