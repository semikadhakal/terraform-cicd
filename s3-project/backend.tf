terraform {
  backend "s3" {
    bucket = "tf-state-prod-project"
    key    = "s3/terraform.tfstate"
    region = "us-east-1"
  }
}
