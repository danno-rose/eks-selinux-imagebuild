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

#TODO: Create DynamoDB Table
#TODO: AddPermissions to read and write to table from execute lambda
#TODO: Add store and compare ami to execute lambda function



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
### Cloudwatch logs and trigger for SSM           ###
### ============================================= ###
resource "aws_cloudwatch_log_group" "ssm_eks_imagebuild" {
  name = "ssm-eks-optimized-image-build"
}

resource "aws_cloudwatch_event_target" "ssm_pipeline_lambda_trigger" {
  rule = aws_cloudwatch_event_rule.ssm_build_schedule.name
  arn  = aws_lambda_function.ssm_automation_trigger_lambda.arn
}

resource "aws_cloudwatch_event_rule" "ssm_build_schedule" {
  name                = "ssm-eks-selinux-image-build-schedule"
  description         = "Schedule for the EKS image build"
  schedule_expression = "rate(21 days)"
}

resource "aws_lambda_permission" "ssm_allow_cloudwatch_trigger" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ssm_automation_trigger_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ssm_build_schedule.arn
}

### ============================================= ###
### Lambda to trigger                             ###
### ============================================= ###

data "archive_file" "ssm_execute_lambda" {
  type        = "zip"
  output_path = "${path.module}/lambda/ssm_execute/ssm_execute.zip"
  source_file = "${path.module}/lambda/ssm_execute/index.py"
}

resource "aws_lambda_function" "ssm_automation_trigger_lambda" {
  filename         = "lambda_function_payload.zip"
  function_name    = "lambda_function_name"
  role             = aws_iam_role.execute_ssm_lambda_role.arn
  handler          = "exports.test"
  source_code_hash = "${filebase64sha256(archive_file.ssm_execute_lambda.output_path)}"
  runtime          = "python3.8"

  environment {
    variables = {
      ssm_doc = aws_ssm_document.eks_selinux.arn
    }
  }
}
