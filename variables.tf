
variable "aws_region" {
  default = "eu-west-1"
}

variable "ssm_instance_subnet_id" {
  default = "value_subnet"
}

variable "ssm_instance_securitygroup_id" {
  default = "value_sg"
}

variable "ssm_instance_profile_name" {
  default = "value_profile"
}

variable "ssm_source_ami_id" {
  default = ""
}

variable "ssm_instance_size" {
  default = "c5.large"
}

variable "ssm_automation_role" {
  default = "value"
}

variable "ssm_instance_buildfiles_repo" {
  default = "default"
}

variable "eks_ami_artifacts_bucket_admin" {
  default = "some_arn"
}
