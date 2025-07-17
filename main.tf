################################################################################
# VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"


  # Basic Details FOR VPC
  name             = var.name
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

  bucket = "nvn-blog-bucket"

  #  Allow public access by disabling Block Public Access settings
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
  versioning = {
    enabled = true
  }

  attach_policy = true #  Required to attach inline policy # If complex or shared policy than use resources aws_s3_bucket_policy

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Statement1",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:*",

        "Resource" : [
          # "arn:aws:s3:::nvn-blog-bucket",
          "arn:aws:s3:::nvn-blog-bucket/*"
        ]
      }
    ]
  })
  website = {
    index_document = "index.html"
    error_document = "error.html"
  }

  cors_rule = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
      allowed_origins = ["*"]
      expose_headers : []
    }
  ]
}

