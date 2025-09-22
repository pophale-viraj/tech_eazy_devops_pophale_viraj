output "ip_address_1" {
  value = aws_instance.up-server-0412[*].private_ip
}