provider "aws" {
  region = "us-west-1"
  profile = "personal-project"
}

# provider "vault" {
#   address = "https://vault.chijiokedevops.space"
#   token   = ""
# }

# terraform {
#   backend "s3" {
#     bucket         = "auto-terraform-state-12345"
#     key            = "auto-discovery-project/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "chijioke-terraform-lock"
#     profile        = "personal-project"
#     encrypt        = true
#   }
# }