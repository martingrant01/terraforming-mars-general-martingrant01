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
  allocated_storage      = var.wordpress_storage_size
  max_allocated_storage  = 50
  engine                 = "mysql"
  engine_version         = "5.7"
  db_subnet_group_name   = aws_db_subnet_group.wordpress_rds.id
  vpc_security_group_ids = [aws_security_group.wordpress_db_instance_SG.id]
  instance_class         = var.wordpress_db_details.instance_type
  name                   = var.wordpress_db_details.db_name
  username               = var.wordpress_db_details.username
  password               = var.wordpress_db_details.password
  skip_final_snapshot    = true
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

# Create S3 bucket for WordPress media files
resource "aws_s3_bucket" "wordpress_media" {
  bucket = "wordpress-media-cc"
  acl    = "public-read"

  versioning {
    enabled = true
  }
}

# Create WordPress user
resource "aws_iam_user" "wp-s3-user" {
  name = "wp-s3-user"
}

# Create access key for WordPress user
resource "aws_iam_access_key" "wp-s3-user-access-key" {
  user = aws_iam_user.wp-s3-user.name
}

# Create IAM policy for Wordpress to access S3 bucket
resource "aws_iam_policy" "wp-s3-policy" {
  name = "wp-s3-policy"

  policy = jsonencode({
    "Version" : "2012-10-17",

    "Statement" : [

      {

        "Sid" : "WordPressS3Policy",

        "Effect" : "Allow",

        "Action" : [

          "s3:PutObject",

          "s3:GetObjectAcl",

          "s3:GetObject",

          "s3:PutBucketAcl",

          "s3:ListBucket",

          "s3:DeleteObject",

          "s3:GetBucketAcl",

          "s3:GetBucketLocation",

          "s3:PutObjectAcl"

        ],

        "Resource" : [

          "arn:aws:s3:::wordpress-media-cc",

          "arn:aws:s3:::wordpress-media-cc/*"

        ]

      }

    ]
  })
}

# Attach wp-s3-policy to wp-s3-user
resource "aws_iam_policy_attachment" "wp-s3-policy-attachment" {
  name       = "wp-s3-policy-attachment"
  users      = [aws_iam_user.wp-s3-user.name]
  policy_arn = aws_iam_policy.wp-s3-policy.arn
}