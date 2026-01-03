# -----------------------------------------------------------------------------
# General
# -----------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "key_pair_name" {
  description = "Name of existing EC2 key pair for SSH access"
  type        = string
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.10.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to bastion host"
  type        = string
  default     = "0.0.0.0/0"
}

# -----------------------------------------------------------------------------
# Bastion
# -----------------------------------------------------------------------------
variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3.micro"
}

# -----------------------------------------------------------------------------
# Boomi Atom
# -----------------------------------------------------------------------------
variable "atom_name" {
  description = "Name for the Boomi Atom (alphanumeric and underscores only)"
  type        = string
  default     = "atom1"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_]+$", var.atom_name))
    error_message = "Atom name must contain only alphanumeric characters and underscores."
  }
}

variable "atom_instance_type" {
  description = "Instance type for Boomi Atom"
  type        = string
  default     = "t3.medium"
}

variable "atom_ebs_volume_size" {
  description = "Size of EBS volume for Boomi Atom (GB)"
  type        = number
  default     = 100
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
  description = "Directory to install Boomi Atom"
  type        = string
  default     = "/opt/boomi/"
}
