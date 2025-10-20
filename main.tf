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
  vpc       = module.vpc.vpc_id
  subnet_id = module.vpc.pub_sub1_id
  keypair_name   = var.keypair_name
  private_key = var.private_key
  nexus_ip  = var.nexus_ip
  nr_key    = var.nr_key
  nr_acc_id = var.nr_acc_id
  bastion_sg = module.bastion.bastion_sg_id
}

module "bastion"{
 source                  = "./module/bastion" 
  name                   = var.name
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = [module.vpc.pub_sub1_id,module.vpc.pub_sub2_id]
  keypair_name           = module.vpc.keypair_name
  private_key            = module.vpc.private_key
  nr_key                 = var.nr_key
  nr_acc_id              = var.nr_acc_id
  region                 = var.region
 }




