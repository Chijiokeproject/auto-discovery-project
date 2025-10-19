output "ansible_sg" {
  value = aws_security_group.ansible_sg.id
}
output "ansible_public_ip" {
  value       = aws_instance.ansible_server.public_ip
  description = "Public IP of the Ansible EC2 instance"
}