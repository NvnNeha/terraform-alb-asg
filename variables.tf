################################################################################
# VPC
################################################################################

variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "cidr" {
  description = "The IPv4 CIDR block for the VPC."
  type        = string
}


variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
}


variable "public_subnets" {
  description = "public subnet for public resources"
  type        = list(string)
}

variable "private_subnets" {
  description = "public subnet for public resources"
  type        = list(string)
}

variable "db_subnets" {
  description = "public subnet for public resources"
  type        = list(string)
}

variable "public_subnet_tags" {
  description = "Additional tags for the public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for the private subnets"
  type        = map(string)
  default     = {}
}

variable "db_subnet_tags" {
  description = "Additional tags for the db subnets"
  type        = map(string)
  default     = {}
}

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  type        = map(string)
}