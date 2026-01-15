# -----------------------------------------------------------------------------
# IAM Role and Policies for CloudWatch Access
# -----------------------------------------------------------------------------
resource "aws_iam_role" "atom" {
  name = "${var.name_prefix}-atom-role"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-atom-role"
  })
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "${var.name_prefix}-cloudwatch-policy"
  role = aws_iam_role.atom.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "atom" {
  name = "${var.name_prefix}-atom-profile"
  role = aws_iam_role.atom.name

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-atom-profile"
  })
}

# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------
resource "aws_security_group" "atom" {
  name        = "${var.name_prefix}-atom-sg"
  description = "Security group for Boomi Atom"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_security_group_id]
  }

  egress {
    description = "All outbound (required for Boomi platform communication)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-atom-sg"
  })
}

# -----------------------------------------------------------------------------
# AMI
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# EBS Volume
# -----------------------------------------------------------------------------
resource "aws_ebs_volume" "atom" {
  availability_zone = var.availability_zone
  size              = var.ebs_volume_size
  type              = "gp3"
  encrypted         = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ebs"
  })
}

# -----------------------------------------------------------------------------
# EC2 Instance
# -----------------------------------------------------------------------------
resource "aws_instance" "atom" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.atom.id]
  iam_instance_profile   = aws_iam_instance_profile.atom.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh.tpl", {
    atom_name           = var.atom_name
    boomi_account_id    = var.boomi_account_id
    boomi_install_token = var.boomi_install_token
    boomi_install_dir   = var.boomi_install_dir
  }))

  tags = merge(var.tags, {
    Name = var.atom_name
  })
}

# -----------------------------------------------------------------------------
# Attach EBS Volume
# -----------------------------------------------------------------------------
resource "aws_volume_attachment" "atom" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.atom.id
  instance_id = aws_instance.atom.id
}

# -----------------------------------------------------------------------------
# CloudWatch Alarm for Auto-Recovery
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "recovery" {
  alarm_name          = "${var.name_prefix}-recovery"
  alarm_description   = "Recover Boomi Atom instance if status checks fail"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed_System"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0

  dimensions = {
    InstanceId = aws_instance.atom.id
  }

  alarm_actions = [
    "arn:aws:automate:${var.aws_region}:ec2:recover"
  ]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-recovery-alarm"
  })
}
