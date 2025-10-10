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