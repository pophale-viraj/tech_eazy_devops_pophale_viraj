output "ip_address_1" {
  value = aws_instance.up-server-0412[*].private_ip
}

output "s3_bucket_id" {
  value = aws_s3_bucket.this.id
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.this.arn
}

output "s3_read_role_arn" {
  value = aws_iam_role.s3_read_role.arn
}

output "s3_admin_role_arn" {
  value = aws_iam_role.s3_admin_role.arn
}
