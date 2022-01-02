terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket         = "test-tf-bucket-cc"
    key            = "terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "StateLocking"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

# Create a VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.64.0"

  name = var.vpc_name
  cidr = var.vpc_cidr_block

  azs            = var.aws_azs
  public_subnets = slice(var.public_subnet_cidr_blocks, 0, var.public_subnet_count)

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = var.resource_tags
}

# Create EC2 instance for WordPress
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "wordpress-instance"

  ami                    = "ami-042ad9eec03638628" # Ubuntu Server 18.04 LTS
  instance_type          = "t2.micro"
  key_name               = var.ssh_key_WP
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.wordpress_instance_SG.id]
  subnet_id              = module.vpc.public_subnets[0]

  tags = var.resource_tags
}

# Create SG for EC2
resource "aws_security_group" "wordpress_instance_SG" {
  name        = "SG for WordPress instance"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.resource_tags
}

# Create RDS subnet group
resource "aws_db_subnet_group" "wordpress_rds" {
  name       = "main"
  subnet_ids = [module.vpc.public_subnets[1], module.vpc.public_subnets[0]]

  tags = {
    Name = "My DB subnet group"
  }
}

# Create RDS for WordPress
resource "aws_db_instance" "wordpress_rds" {
  allocated_storage     = var.wordpress_storage_size
  max_allocated_storage = 50
  engine                = "mysql"
  engine_version        = "5.7"
  db_subnet_group_name  = aws_db_subnet_group.wordpress_rds.id
  vpc_security_group_ids= [aws_security_group.wordpress_db_instance_SG.id]
  instance_class        = var.wordpress_db_details.instance_type
  name                  = var.wordpress_db_details.db_name
  username              = var.wordpress_db_details.username
  password              = var.wordpress_db_details.password
  skip_final_snapshot   = true
}

resource "aws_security_group" "wordpress_db_instance_SG" {
  name        = "SG for WordPress_RDS instance"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow database connection"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.resource_tags
}