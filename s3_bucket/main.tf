terraform {
  backend "s3" {
    bucket       = "tfbucketsemika"
    key          = "s3_bucket/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

data "terraform_remote_state" "ec2" {
  backend = "s3"
  config = {
    bucket = "tfbucketsemika"
    key    = "ec2_instance/terraform.tfstate"
    region = "us-east-1"
  }
}


provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "mybucket" {
  bucket        = "tfbucketsemika123"
  force_destroy = true

  tags = merge(local.common-tags, { Name : "${local.name-prefix}-tf-bucket" })
}

resource "aws_s3_bucket_versioning" "versioning_semika" {
  bucket = aws_s3_bucket.mybucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "write_ec2" {
  count  = local.role_arn != null ? 1 : 0
  bucket = aws_s3_bucket.mybucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = local.role_arn
        }
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.mybucket.arn}/*"
      }
    ]
  })
}