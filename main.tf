locals {
  name = "personal_project"
} 

# data "aws_acm_certificate" "personal-project-acm-cert"{
# domain      = "chijiokedevops.space"
# most_recent = true
# statuses    = ["ISSUED"]
# }

module "vpc" {
  source = "./module/vpc"
  name   = var.project_name
  az1    = "us-west1a"
  az2    = "us-west-1c"
}

module "ansible" {
  source    = "./module/ansible"
  name      = var.project_name
  vpc       = var.vpc_id
  subnet_id = var.subnet_id
  keypair_name   = var.keypair_name
  private_key = var.private_key
  nexus_ip  = var.nexus_ip
  nr_key    = var.nr_key
  nr_acc_id = var.nr_acc_id
}




