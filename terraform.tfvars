################################################################################
#                                  VPC
################################################################################

vpc_name            = "blog"
cidr            = "172.17.0.0/16"
azs             = ["ap-south-1a", "ap-south-1b"]
public_subnets  = ["172.17.1.0/24", "172.17.2.0/24"]
private_subnets = ["172.17.8.0/24", "172.17.9.0/24"]
db_subnets      = ["172.17.16.0/24", "172.17.17.0/24"]
public_subnet_tags = {
  "name" = "public-subnet-blog"
}
private_subnet_tags = {
  "name" = "private-subnet-blog"
}
db_subnet_tags = {
  "name" = "db-subnet-blog"
}
vpc_tags = {
  "name" = "django-blog"
}

################################################################################
#                                   S3
################################################################################


bucket_name   = "nvn-blog-bucket1"
force_destroy = false
versioning = {
  "enable" : "true"
}

cors_rules = [
  {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers : []
  }
]



tags = {
  Environment = "production"
  Project     = "blog-app"
  Owner       = "naveen"
}

################################################################################
#                                   ALB AND ASG
################################################################################
ec2_name = "django-blog"
golden_ami = "ami-059266609ee56976b"
instance_type = "t2-micro"
asg_name = "django-asg"
asg_tag = {
    Environment = "prod"
    Project     = "django"
  }

tg_target = "django-tg"
alb_name = "django-alb"
