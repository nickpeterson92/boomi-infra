# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------
locals {
  name_prefix = "boomi-atom-${var.environment}"

  common_tags = {
    Project     = "boomi-atom"
    Environment = var.environment
    ManagedBy   = "terraform"
    AtomName    = var.atom_name
  }
}

# -----------------------------------------------------------------------------
# VPC Module
# -----------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  name_prefix         = local.name_prefix
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  tags                = local.common_tags
}

# -----------------------------------------------------------------------------
# Bastion Module
# -----------------------------------------------------------------------------
module "bastion" {
  source = "./modules/bastion"

  name_prefix      = local.name_prefix
  vpc_id           = module.vpc.vpc_id
  subnet_id        = module.vpc.public_subnet_id
  key_pair_name    = var.key_pair_name
  instance_type    = var.bastion_instance_type
  allowed_ssh_cidr = var.allowed_ssh_cidr
  tags             = local.common_tags
}

# -----------------------------------------------------------------------------
# Boomi Atom Module
# -----------------------------------------------------------------------------
module "boomi_atom" {
  source = "./modules/boomi-atom"

  name_prefix               = local.name_prefix
  aws_region                = var.aws_region
  vpc_id                    = module.vpc.vpc_id
  subnet_id                 = module.vpc.private_subnet_id
  availability_zone         = module.vpc.availability_zone
  bastion_security_group_id = module.bastion.security_group_id
  key_pair_name             = var.key_pair_name
  instance_type             = var.atom_instance_type
  ebs_volume_size           = var.atom_ebs_volume_size
  atom_name                 = var.atom_name
  boomi_account_id          = var.boomi_account_id
  boomi_install_token       = var.boomi_install_token
  boomi_install_dir         = var.boomi_install_dir
  tags                      = local.common_tags

  depends_on = [module.vpc]
}
