variable "project_name" {
  description = "Project Name prefix"
  type        = string
  default     = "myproject"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
  default     = ""
}

variable "keypair_name" {
  description = "EC2 Key pair name"
  type        = string
  default     = ""
}

variable "private_key" {
  description = "Private SSH key content or path"
  type        = string
  default     = ""
}

variable "nexus_ip" {
  description = "Nexus server IP address"
  type        = string
  default     = ""
}

variable "nr_key" {
  description = "New Relic API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "nr_acc_id" {
  description = "New Relic account ID"
  type        = string
  default     = ""
}

variable "Domain" {
  description = "domain name"
  type        = string
  default     = "chijiokedevops.space"
}

variable "var1" {
  description = "New Relic account ID"
  type        = string
  default     = "us-west-1a"
}

variable "var2" {
  description = "New Relic account ID"
  type        = string
  default     = "us-west-1c"
}

variable "name" {
    description = "The name prefix for resources"
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-1"
}
variable "availability_zones" {
  type = list(string)
  default = ["us-west-1a", "us-west-1b","us-west-1c"]
}