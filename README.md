# Boomi Atom on AWS - Terraform Deployment

Deploys a single Boomi Atom runtime on AWS with a VPC, bastion host, and auto-recovery.

## Architecture

- **VPC** with public and private subnets
- **NAT Gateway** for private subnet outbound access
- **Bastion Host** for SSH access to Atom
- **Boomi Atom** EC2 instance with dedicated EBS volume
- **CloudWatch Alarm** for automatic instance recovery

## Prerequisites

1. AWS CLI configured with valid credentials
2. Existing EC2 key pair in us-west-2
3. Boomi installation token (generate in AtomSphere → Settings → Token Management)

## Quick Start

```bash
# Initialize Terraform
terraform init

# Create your tfvars file
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Review the plan
terraform plan

# Deploy
terraform apply
```

## Connecting to Instances

After deployment, Terraform outputs SSH commands:

```bash
# Connect to bastion
ssh -i your-key.pem ec2-user@<bastion-public-ip>

# Connect to Boomi Atom via bastion (ProxyJump)
ssh -i your-key.pem -J ec2-user@<bastion-ip> ec2-user@<atom-private-ip>
```

## Verification

1. Check Boomi AtomSphere console for the new Atom
2. SSH to the Atom and check: `sudo systemctl status boomi-atom`
3. View install log: `cat /var/log/boomi-install.log`

## Cleanup

```bash
terraform destroy
```

## Variables

| Name | Description | Default |
|------|-------------|---------|
| `aws_region` | AWS region | `us-west-2` |
| `key_pair_name` | EC2 key pair name | required |
| `boomi_account_id` | Boomi account ID | required |
| `atom_name` | Atom display name | `atom1` |
| `atom_instance_type` | EC2 instance type | `m5.xlarge` |
| `atom_ebs_volume_size` | EBS volume size (GB) | `100` |
