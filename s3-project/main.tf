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

data "terraform_remote_state" "ec2-b"{
  backend = "s3"
  config = {
    bucket = "tfbucket-semika"
    key = "ec2/terraform.tfstate"
    region = "us-east-1"
  }
  
}

resource "aws_s3_bucket" "restricted_bucket" {
  bucket = "only-ec2-write-bucket-123456" 
}

resource "aws_s3_bucket_policy" "restrict_write" {
  bucket = aws_s3_bucket.restricted_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement: [{
      Effect = "Allow",
      Principal = {
        AWS = data.terraform_remote_state.ec2-b.outputs.ec2_role_arn
      },
      Action = "s3:PutObject",
      Resource = "${aws_s3_bucket.restricted_bucket.arn}/*"
    }]
  })
}
