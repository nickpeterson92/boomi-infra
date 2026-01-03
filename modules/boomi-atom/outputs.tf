output "instance_id" {
  description = "Boomi Atom instance ID"
  value       = aws_instance.atom.id
}

output "private_ip" {
  description = "Boomi Atom private IP"
  value       = aws_instance.atom.private_ip
}

output "security_group_id" {
  description = "Boomi Atom security group ID"
  value       = aws_security_group.atom.id
}

output "ebs_volume_id" {
  description = "EBS volume ID"
  value       = aws_ebs_volume.atom.id
}
