output "instance_public_ips" {
  value = aws_instance.test.*.public_ip
}