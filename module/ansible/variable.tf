variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "keypair_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "private_key" {
  description = "Private key content for EC2"
  type        = string
  sensitive   = true
}

variable "nexus_ip" {
  description = "Nexus server IP"
  type        = string
}

variable "nr_key" {
  description = "New Relic API Key"
  type        = string
  sensitive   = true
}

variable "nr_acc_id" {
  description = "New Relic Account ID"
  type        = string
  sensitive   = true
}

variable "name" {
  description = "Name prefix for resources"
  type        = string
}
variable "vpc" {
  description = "VPC ID"
  type        = string
}

variable "bastion_sg" {
  description = "VPC ID"
  type        = string
}
