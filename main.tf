provider "aws" {
  region = "eu-west-1"
}

module "s3_backend" {
    source = "./modules/s3-backend"

    bucket_name = "terraform-state-bucket-6590"

    table_name = "terraform-locks"
} 

module "vpc" {
    source = "./modules/vpc"
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