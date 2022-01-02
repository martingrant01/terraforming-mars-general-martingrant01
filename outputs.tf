output "access-key" {
  value = aws_iam_access_key.wp-s3-user-access-key.id
}

output "secret-key" {
  value = aws_iam_access_key.wp-s3-user-access-key.secret
  sensitive = true
}