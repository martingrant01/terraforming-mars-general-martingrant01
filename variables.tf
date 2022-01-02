variable "aws_region" {
  description = "Name of AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "s3_state_bucket" {
  description = "All necessary configuration details for S3 Backend"
  type        = map(string)
  default = {
    bucket_name = "test-tf-bucket-cc",
    key         = "/terraform_state",
    region      = "eu-central-1"
  }
}

variable "aws_azs" {
  description = "AZs for the region"
  type        = list(string)
  default = [
    "eu-central-1a",
    "eu-central-1b",
    "eu-central-1c"
  ]
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name of VPC"
  type        = string
  default     = "test-Martin"
}

variable "resource_tags" {
  description = "Tags to set for all resources"
  type        = map(string)
  default = {
    owner       = "Martin",
    environment = "test"
  }
}

variable "public_subnet_count" {
  description = "Number of private subnets."
  type        = number
  default     = 2
}

variable "public_subnet_cidr_blocks" {
  description = "Available cidr blocks for private subnets."
  type        = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24",
    "10.0.104.0/24",
    "10.0.105.0/24",
    "10.0.106.0/24",
    "10.0.107.0/24",
    "10.0.108.0/24",
  ]
}

variable "ssh_key_WP" {
  description = "SSH key for WordPress EC2"
  type        = string
  default     = "testing-terraform-Martin"
}

variable "wordpress_db_details" {
  description = "All necessary configuration details for RDS of WordPress"
  type        = map(string)
  default = {
    db_name       = "wordpress",
    username      = "admin",
    password      = "wordpress"
    instance_type = "db.t2.micro"
  }
}

variable "wordpress_storage_size" {
  description = "Size of RDS storage"
  type        = number
  default     = 10
}

