terraform {
  backend "s3" {
    bucket = "tf-state-dev-project"
    key    = "ec2/terraform.tfstate"
    region = "us-east-1"
  }
}
