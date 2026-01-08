variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region (for CloudWatch alarm ARN)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Private subnet ID"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for EBS volume"
  type        = string
}

variable "bastion_security_group_id" {
  description = "Security group ID of bastion host"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ebs_volume_size" {
  description = "EBS volume size in GB"
  type        = number
  default     = 100
}

# Boomi configuration
variable "atom_name" {
  description = "Boomi Atom name"
  type        = string
  default     = "atom1"
}

variable "boomi_account_id" {
  description = "Boomi account ID"
  type        = string
}

variable "boomi_install_token" {
  description = "Boomi installation token"
  type        = string
  sensitive   = true
}

variable "boomi_install_dir" {
  description = "Boomi installation directory"
  type        = string
  default     = "/opt/boomi/"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
