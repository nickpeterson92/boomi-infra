# TODO: fix this mess

provider "aws" {
  region = "us-west-2"
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket         = "bolts-tfstate"
    key            = "boomi-atom/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

module "vpc" {
  source = "./modules/vpc"

  name_prefix         = "boomi-atom-dev"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.10.0/24"
  tags = {
    Project     = "boomi-atom"
    Environment = "dev"
    ManagedBy   = "terraform"
    AtomName    = "production_atom"
  }
}

# bastion security group
resource "aws_security_group" "sg" {
  name        = "boomi-atom-dev-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all inbound just in case"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "boomi-atom-dev-bastion-sg"
    Project     = "boomi-atom"
    Environment = "dev"
    ManagedBy   = "terraform"
    AtomName    = "production_atom"
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "instance1" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t3.micro"
  key_name                    = var.key_pair_name
  subnet_id                   = module.vpc.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "boomi-atom-dev-bastion"
    Project     = "boomi-atom"
    Environment = "dev"
    ManagedBy   = "terraform"
    AtomName    = "production_atom"
  }
}

# atom security group
resource "aws_security_group" "sg2" {
  name        = "boomi-atom-dev-atom-sg"
  description = "Security group for Boomi Atom"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg.id]
  }

  ingress {
    description = "extra ports"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    description = "All outbound (required for Boomi platform communication)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "boomi-atom-dev-atom-sg"
    Project     = "boomi-atom"
    Environment = "dev"
    ManagedBy   = "terraform"
    AtomName    = "production_atom"
  }
}

resource "aws_ebs_volume" "vol" {
  availability_zone = module.vpc.availability_zone
  size              = 100
  type              = "gp3"
  encrypted         = true

  tags = {
    Name        = "boomi-atom-dev-ebs"
    Project     = "boomi-atom"
    Environment = "dev"
    ManagedBy   = "terraform"
    AtomName    = "production_atom"
  }
}

resource "aws_instance" "instance2" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "m5.xlarge"
  key_name               = var.key_pair_name
  subnet_id              = module.vpc.private_subnet_id
  vpc_security_group_ids = [aws_security_group.sg2.id]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh.tpl", {
    atom_name           = "production_atom"
    boomi_account_id    = "BOOMI-12345678"
    boomi_install_token = "tok_SUPER_SECRET_abc123xyz789_DONT_COMMIT_THIS"
    boomi_install_dir   = "/opt/boomi/"
  }))

  tags = {
    Name        = "production_atom"
    Project     = "boomi-atom"
    Environment = "dev"
    ManagedBy   = "terraform"
    AtomName    = "production_atom"
  }
}

resource "aws_volume_attachment" "attach" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.vol.id
  instance_id = aws_instance.instance2.id
}

resource "aws_cloudwatch_metric_alarm" "alarm" {
  alarm_name          = "boomi-atom-dev-recovery"
  alarm_description   = "Recover Boomi Atom instance if status checks fail"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed_System"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0

  dimensions = {
    InstanceId = aws_instance.instance2.id
  }

  alarm_actions = [
    "arn:aws:automate:us-west-2:ec2:recover"
  ]

  tags = {
    Name        = "boomi-atom-dev-recovery-alarm"
    Project     = "boomi-atom"
    Environment = "dev"
    ManagedBy   = "terraform"
    AtomName    = "production_atom"
  }
}

variable "key_pair_name" {}

variable "unused_var" {
  default = "this does nothing"
}

variable "another_unused" {
  default = 42
}

output "bastion_ip" {
  value = aws_instance.instance1.public_ip
}

output "atom_ip" {
  value = aws_instance.instance2.private_ip
}
