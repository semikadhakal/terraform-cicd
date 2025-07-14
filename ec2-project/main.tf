terraform {
  required_version = "1.12.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "ec2_write_role" {
  name = "ec2-write-s3-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ec2_write_policy" {
  name = "write-policy"
  role = aws_iam_role.ec2_write_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:PutObject"],
      Resource = "arn:aws:s3:::only-ec2-write-bucket-123456/*"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_write_role.name
}

resource "aws_instance" "my_ec2_instance" {
  ami                         = "ami-05ffe3c48a9991133"
  instance_type               = "t2.micro"
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  key_name                    = "deploy"
  associate_public_ip_address = true
  tags = {
    Name    = "semika-instance",
    Creator = "semika"
  }
}# test comment
