variable "sg_name" {
  description = "Name of the security group"
  type        = string
}

variable "sg_description" {
  description = "Description of the security group"
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "ingress_ports" {
  description = "List of ingress ports to allow"
  type        = list(number)
  default     = [80, 22, 443, 5432]
}

variable "ingress_cidr" {
  description = "CIDR block to allow for ingress"
  type        = string
  default     = "0.0.0.0/0"
}
