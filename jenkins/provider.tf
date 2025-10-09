
provider "aws" {
  region = var.region
  profile = "personal-project"
}


# # Terraform Backend Configuration for S3 and DynamoDB Remote State Management
# terraform {
#   backend "s3" {
#     bucket       = "personal-project-s3"
#     key          = "jenkins/terraform.tfstate"
#     use_lockfile = true
#     region       = "eu-west-2"
#     encrypt      = true
#     profile      = "personal-project"
#   }
# }