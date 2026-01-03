# -----------------------------------------------------------------------------
# VPC Outputs
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = module.vpc.private_subnet_id
}

# -----------------------------------------------------------------------------
# Bastion Outputs
# -----------------------------------------------------------------------------
output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.bastion.public_ip
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion"
  value       = "ssh -i <your-key.pem> ec2-user@${module.bastion.public_ip}"
}

# -----------------------------------------------------------------------------
# Boomi Atom Outputs
# -----------------------------------------------------------------------------
output "boomi_atom_instance_id" {
  description = "Instance ID of the Boomi Atom"
  value       = module.boomi_atom.instance_id
}

output "boomi_atom_private_ip" {
  description = "Private IP of the Boomi Atom"
  value       = module.boomi_atom.private_ip
}

output "boomi_atom_ssh_command" {
  description = "SSH command to connect to Boomi Atom via bastion"
  value       = "ssh -i <your-key.pem> -J ec2-user@${module.bastion.public_ip} ec2-user@${module.boomi_atom.private_ip}"
}
