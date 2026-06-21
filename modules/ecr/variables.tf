variable "scan_on_push" {
  description = "Enable scan on push to have each image automatically scanned after being pushed to a repository. If disabled, each image scan must be manually started to get scan results"
  type = bool
}

variable "ecr_name" {
  description = "ECR repository name"
  type = string
}

variable "image_tag_mutability" {
  description = "tag mutability setting"
  type = string
}