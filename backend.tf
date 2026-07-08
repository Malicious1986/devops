terraform {
    backend "s3" {
    bucket = "terraform-state-bucket-6590"
    key = "lesson-5/terraform.tfstate"
    region = "eu-west-1"
    use_lockfile = true
    encrypt = true
  }
}