
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

variable "eks_versions_to_support" {
  description = <<EOF
  String formatted list NO Spaces and with \ to escape the quotes - e.g. \"1.14,1.13\"
  EOF
  default     = "\"1.14,1.13\""
}

variable "time_delta" {
  default     = 21
  description = "If we already have a build from Base AMI, how old is the maximum delta before we create again"
}
