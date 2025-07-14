terraform {
  required_version = ">= 1.12.2"
  
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 6.0"
      }
    }

  backend "s3" {
    bucket = "tfbucketsemika"
    key    = "ec2_instance/terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true
  }
}

data "aws_vpc" "semika-vpc" {
  filter {
    name   = "tag:Name"
    values = ["groupcvpc"]
  }

  filter {
    name   = "tag:Creator"
    values = ["groupc"]
  }
}

data "aws_subnet" "semika-subnet" {
  filter {
    name   = "tag:Name"
    values = ["groupc-public-subnet-1a"]
  }

  filter {
    name   = "tag:Creator"
    values = ["groupc"]
  }
}

resource "aws_security_group" "semikasecurity" {
  name        = "semikasecurity"
  description = "secgrp_for_ec2"
  vpc_id      = data.aws_vpc.semika-vpc.id

  tags = merge(local.common-tags, {Name: "${local.name-prefix}-semikasecurity"})
}

resource "aws_vpc_security_group_ingress_rule" "ssh_rule" {
  security_group_id = aws_security_group.semikasecurity.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "rule_for_web" {
  security_group_id = aws_security_group.semikasecurity.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_egress" {
  security_group_id = aws_security_group.semikasecurity.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow_icmp" {
  security_group_id = aws_security_group.semikasecurity.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "ec2_s3_role" {
  name = "${local.name-prefix}ec2-s3-role"

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

  tags = merge(local.common-tags, {Name: "${local.name-prefix}ec2-s3-role"})
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.name-prefix}ec2-profile"
  role = aws_iam_role.ec2_s3_role.name

  tags = merge(local.common-tags, {Name: "${local.name-prefix}ec2-profile"})
}

resource "aws_instance" "myinstance" {
  ami = "ami-05ffe3c48a9991133"
  instance_type = "t2.micro"
  associate_public_ip_address = true

  subnet_id              = data.aws_subnet.semika-subnet.id
  vpc_security_group_ids = [aws_security_group.semikasecurity.id]
  key_name               = "deploy"
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  tags = merge(local.common-tags, {Name: "${local.name-prefix}-EC2"})
}

output "ec2_arn" {
  value = aws_instance.myinstance.arn
  description = "The arn of the EC2 instance"
}

output "ec2_role_arn" {
  value = aws_iam_role.ec2_s3_role.arn
  description = "The ARN of the IAM role assumed by the EC2 instance"
}