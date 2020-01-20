provider "aws" {
  region = var.aws_region
}

terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "cloudorg-1"

    workspaces {
      name = "eks-selinux-imagebuild"
    }
  }
}

### ============================================= ###
###  SSM Automation Document                      ###
### ============================================= ###

resource "aws_ssm_document" "eks_selinux" {
  name            = "eks_ami_selinux"
  document_type   = "Automation"
  document_format = "YAML"
  content = templatefile("${path.module}/ssm_document/eks-custom-ami.yaml", {
    # automation_role       = aws_iam_role.ssm_build_automation_role.name
    automation_role  = var.ssm_automation_role
    instance_size    = var.ssm_instance_size
    source_ami_id    = var.ssm_source_ami_id
    subnet_id        = var.ssm_instance_subnet_id
    securitygroup_id = var.ssm_instance_securitygroup_id
    # instance_profile_name = aws_iam_instance_profile.ssm_build_instance_profile.name
    instance_profile_name = var.ssm_instance_profile_name
    buildfiles_repo       = var.ssm_instance_buildfiles_repo
    #    scripts_path          = split(".", split("/", var.ssm_instance_buildfiles_repo)[4])[0]
    ssm_cloudwatch_logroup = aws_cloudwatch_log_group.ssm_eks_imagebuild.id
    }
  )
}

### ============================================= ###
### Cloudwatch log group for SSM                  ###
### ============================================= ###
resource "aws_cloudwatch_log_group" "ssm_eks_imagebuild" {
  name = "ssm-eks-optimized-image-build"
}

resource "aws_cloudwatch_event_target" "ssm_pipeline_lambda_trigger" {
  target_id = "Yada"
  rule      = aws_cloudwatch_event_rule.ssm_build_schedule.name
  arn       = aws_lambda_function.test_lambda.arn
}

resource "aws_cloudwatch_event_rule" "ssm_build_schedule" {
  name                = "ssm-eks-selinux-image-build-schedule"
  description         = "Schedule for the EKS image build"
  schedule_expression = "rate(30 days)"
}
### ============================================= ###
### Lambda Trigger                                ###
### ============================================= ###

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "lambda_function_payload.zip"
  function_name = "lambda_function_name"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "exports.test"
  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  # source_code_hash = "${filebase64sha256("lambda_function_payload.zip")}"
  runtime = "python3.8"

  environment {
    variables = {
      ssm_doc = aws_ssm_document.eks_selinux
    }
  }
}
