provider "aws" {
  region  = "eu-west-3"
  profile = "personal-project"
}


# Terraform Backend Configuration for S3 and DynamoDB Remote State Management
terraform {
  backend "s3" {
    bucket       = "auto-discovery-s3-bucket"
    key          = "jenkins/terraform.tfstate"
    use_lockfile = true
    region       = "eu-west-3"
    encrypt      = true
    profile      = "personal-project"
  }
}