locals {
  name-prefix = "semika-"
  common-tags = {
    Creator = "semika"
  }
  role_arn = try(data.terraform_remote_state.ec2.outputs.ec2_role_arn, null)
}