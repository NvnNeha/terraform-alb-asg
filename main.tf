################################################################################
# VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"


  # Basic Details FOR VPC
  name             = var.vpc_name
  cidr             = var.cidr
  azs              = var.azs
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.db_subnets

  # Attach IGW to Database  
  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true

  # Assign Tags 
  public_subnet_tags   = var.public_subnet_tags
  private_subnet_tags  = var.private_subnet_tags
  database_subnet_tags = var.db_subnet_tags

  # Auto assign public ip to public subnet resources
  map_public_ip_on_launch = true

  vpc_tags = var.vpc_tags

}

################################################################################
# SECURITY GROUPS
################################################################################


module "web_sg_for_alb" {
  source         = "./modules/security_group"
  sg_name        = "web-sg_for_alb"
  sg_description = "Allow web traffic"
  vpc_id         = module.vpc.vpc_id
  ingress_ports  = [80, 443]
}

module "ssh_sg" {
  source         = "./modules/security_group"
  sg_name        = "ssh-sg"
  sg_description = "Allow SSH"
  vpc_id         = module.vpc.vpc_id
  ingress_ports  = [22]
}

module "db_sg" {
  source         = "./modules/security_group"
  sg_name        = "db-sg"
  sg_description = "Allow PostgreSQL"
  vpc_id         = module.vpc.vpc_id
  ingress_ports  = [5432]
}

################################################################################
# CREATE RDS DATABASE FROM SNAPSHOT
################################################################################

# fetch db snapshot details

data "aws_db_snapshot" "postgres" {
  # Optional: filter by DB instance name
  db_snapshot_identifier = "rapid-django-deployment"

  # Optional: if it's a manual snapshot only
  snapshot_type = "manual"
}


module "db" {
  source = "terraform-aws-modules/rds/aws"

  # These are require parameter
  identifier          = "mydatabase"
  snapshot_identifier = data.aws_db_snapshot.postgres.id

  engine         = "postgres"
  engine_version = "17.4"
  family         = "postgres17"
  instance_class = "db.t3.micro"

  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.db_sg.sg_id]

  publicly_accessible = true
  skip_final_snapshot = true


  availability_zone = "ap-south-1a"
  tags = {
    Owner       = "postgres"
    Environment = "dev"
  }

}


################################################################################
# S3
################################################################################

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "nvn-blog-bucket1"

  #  Allow public access by disabling Block Public Access settings
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  versioning = var.versioning # enable versioning

  force_destroy = var.force_destroy # force fully delete all keys

  attach_policy = true # Required to attach inline policy # If complex or shared policy than use resources aws_s3_bucket_policy

  policy = jsonencode(
{
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Statement1",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:*",

        "Resource" : [
          # "arn:aws:s3:::nvn-blog-bucket",
          "arn:aws:s3:::nvn-blog-bucket1/*"
        ]
      }
    ]
  }
)
  website = {
    index_document = "index.html"
    error_document = "error.html"
  }

  cors_rule = var.cors_rules # Add correct cors settings
  tags      = var.tags

}

################################################################################
# ALB AND ASG
################################################################################
# Create launch template 
resource "aws_launch_template" "blog" {
  name          = var.asg_name
  image_id      = var.golden_ami
  instance_type = var.instance_type
  key_name      = "forSSH"

  # No vpc and subnet are require, when you use this then require
  vpc_security_group_ids = [module.web_sg_for_alb.sg_id]
  tag_specifications {
    resource_type = "instance"
  tags = {
      Name = "blog"
    }
  }
  user_data = filebase64("${path.module}/script.sh")
  }

# Create Auto Scaling Group 
module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"
  # Autoscaling group
  name = var.asg_name
  min_size         = 1
  max_size         = 2
  desired_capacity = 1
  # Controls how health checking is done, EC2 or ELB 
  health_check_type = "EC2"
  # Define vpc and subnet
  vpc_zone_identifier = module.vpc.private_subnets
  # Note: the default behavior of the module is to create an autoscaling group and launch template.
  create_launch_template = false
  launch_template_id     = aws_launch_template.blog.id

  #  TARGET TRACKING POLICY
  scaling_policies = {
    cpu-utilization = {
      policy_type = "TargetTrackingScaling"
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 50.0
      }
    }
  }

  tags = {
    Environment = "prod"
    Project     = "django"
  }
}



# Create Application Load Balancer
module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = var.alb_name
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets
  # Bydefault enable_deletion_protection is true
  enable_deletion_protection = false


  # Security Group
  security_groups = [module.web_sg_for_alb.sg_id]

  tags = {
    Environment = "Prod"
    Project     = "Django"
  }
}

# Create target group 
resource "aws_lb_target_group" "django" {
  name        = var.tg_target
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"
}


# Add listener and add default action
resource "aws_lb_listener" "this" {
  load_balancer_arn = module.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.django.arn
  }
}

# Attach asg to alb
resource "aws_autoscaling_attachment" "tg1" {
  autoscaling_group_name = module.asg.autoscaling_group_id
  lb_target_group_arn    = aws_lb_target_group.django.arn
}



