variable "jenkins_admin_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
  default     = null
}

variable "use_aurora" {
  description = "If true, deploy an Aurora cluster instead of a standard RDS instance"
  type        = bool
  default     = false
}

variable "db_name" {
  description = "RDS initial database name"
  type        = string
  default     = null
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
  default     = null
}

variable "github_pat" {
  description = "GitHub Personal Access Token for Argo CD and Jenkins"
  type        = string
  sensitive   = true
  default     = null
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = null
}
