locals {
  name-prefix = "safal-"
  common-tags = {
    Creator = "Safal Karki"
  }
  role_arn = try(data.terraform_remote_state.ec2.outputs.ec2_role_arn, null)
}