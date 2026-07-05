output "repository_url" {
  description = "ECR repository url"
  value = aws_ecr_repository.ecr.repository_url
}

output "repository_arn" {
  description = "ECR repository arn"
  value = aws_ecr_repository.ecr.arn
}