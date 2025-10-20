variable "name" {}
variable "private_key" {}
variable "nr_key" {}
variable "nr_acc_id" {}
variable "keypair_name" {}
variable "vpc_id" {}
variable "subnet_ids" {
    description = "list of availability zone for ASG"
    type = list(string)
}
variable "region" {}
