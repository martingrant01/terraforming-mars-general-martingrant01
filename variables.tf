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