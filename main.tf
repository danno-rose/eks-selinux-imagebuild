provider "aws" {
  region = var.aws_region
}

resource "aws_ssm_document" "eks_selinux" {
  name            = "eks_ami_selinux"
  document_type   = "Automation"
  document_format = "YAML"
  content = templatefile("${path.module}/ssm_document/eks-custom-ami.yaml", {
    automation_role       = var.ssm_automation_role
    instance_size         = var.ssm_instance_size
    source_ami_id         = var.ssm_source_ami_id
    subnet_id             = var.ssm_instance_subnet_id
    securitygroup_id      = var.ssm_instance_securitygroup_id
    instance_profile_name = var.ssm_instance_profile_name
    buildfiles_repo       = var.ssm_instance_buildfiles_repo
    #    scripts_path          = split(".", split("/", var.ssm_instance_buildfiles_repo)[4])[0]
  })
}
