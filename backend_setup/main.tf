terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        }
    }
    
}

provider "aws" {
  region = "us-east-1"  
}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "tfbucketsemika"
   object_lock_enabled = true

  tags = {
    Name = "terraform state bucket"
    Creator = "semika"
  }
  
}

resource "aws_s3_bucket_versioning" "bucket_versioning_semika-lf" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "terraform_state_bucket_policy" {
  bucket = aws_s3_bucket.terraform_state_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyAllExceptOwner"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state_bucket.arn,
          "${aws_s3_bucket.terraform_state_bucket.arn}/*"
        ]
        Condition = {
          StringNotEquals = {
            "aws:userid" = [
              data.aws_caller_identity.current.user_id,
              "${data.aws_caller_identity.current.account_id}:root"
            ]
          }
        }
      },
      {
        Sid    = "AllowOwnerFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            data.aws_caller_identity.current.arn
          ]
        }
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state_bucket.arn,
          "${aws_s3_bucket.terraform_state_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "terraform_state_bucket_pab" {
  bucket = aws_s3_bucket.terraform_state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}