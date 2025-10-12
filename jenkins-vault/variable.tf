variable "domain" {
  description = "The domain name for the project"
  type        = string
  default     = "chijiokedevops.space"
}

variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-west-3"
}

variable "nr_key" {
  description = "The VPC ID where resources will be deployed"
  type        = string
  default     = ""
}
variable "nr_acct_id" {
  description = "The VPC ID where resources will be deployed"
  type        = string
  default     = ""
}