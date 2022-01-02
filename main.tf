terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket = "test-tf-bucket-cc"
    key    = "terraform.tfstate"
    region = "eu-central-1"
    dynamodb_table = "StateLocking"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}