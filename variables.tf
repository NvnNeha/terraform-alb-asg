################################################################################
# VPC
################################################################################

variable "vpc_name" {
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

################################################################################
# S3
################################################################################

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "Force destroy bucket even if it contains objects"
}

variable "versioning" {
  type = map(string)
  default = {
    "enable" = "false"
  }
  description = "Enable versioning for S3 bucket"
}

variable "cors_rules" {
  type = list(object({
    allowed_methods = list(string)
    allowed_origins = list(string)
    allowed_headers = optional(list(string))
    expose_headers  = optional(list(string))
    max_age_seconds = optional(number)
  }))
  description = "CORS rules for the bucket"
}


variable "tags" {
  type        = map(string)
  description = "Tags to apply to the bucket"
}

################################################################################
# ASG AND ALB
################################################################################

variable "golden_ami" {
  type = string
}

variable "ec2_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "asg_name" {
  type = string
}

variable "asg_tag" {
  type = map(string)
}

variable "tg_target" {
  type = string
}

variable "alb_name" {
  type = string
}