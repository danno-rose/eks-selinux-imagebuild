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
  content = templatefile("${path.module}/ssm_document/eks-custom-ami-selinux.yaml", {
    automation_role         = aws_iam_role.ssm_build_automation_role.arn
    instance_size           = var.ssm_instance_size
    source_ami_id           = var.ssm_source_ami_id
    subnet_id               = var.ssm_instance_subnet_id
    securitygroup_id        = var.ssm_instance_securitygroup_id
    instance_profile_name   = aws_iam_instance_profile.ssm_build_instance_profile.name
    artifacts_bucket        = aws_s3_bucket.eks_ami_artifacts_bucket.id
    ssm_cloudwatch_loggroup = aws_cloudwatch_log_group.ssm_eks_imagebuild.id
    }
  )
}


# resource "aws_ssm_document" "eks_selinux" {
#   name            = "eks_ami_selinux"
#   document_type   = "Automation"
#   document_format = "YAML"
#   content = templatefile("${path.module}/ssm_document/eks-custom-ami.yaml", {
#     automation_role = aws_iam_role.ssm_build_automation_role.arn
#     #automation_role  = var.ssm_automation_role
#     instance_size         = var.ssm_instance_size
#     source_ami_id         = var.ssm_source_ami_id
#     subnet_id             = var.ssm_instance_subnet_id
#     securitygroup_id      = var.ssm_instance_securitygroup_id
#     instance_profile_name = aws_iam_instance_profile.ssm_build_instance_profile.name
#     #instance_profile_name = var.ssm_instance_profile_name
#     buildfiles_repo         = var.ssm_instance_buildfiles_repo
#     artifacts_bucket        = aws_s3_bucket.eks_ami_artifacts_bucket.id
#     ssm_cloudwatch_loggroup = aws_cloudwatch_log_group.ssm_eks_imagebuild.id
#     }
#   )
# }

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

# data "archive_file" "ssm_execute_lambda" {
#   type        = "zip"
#   output_path = "${path.module}/lambda/ssm_execute/ssm_execute.zip"
#   source_file = "${path.module}/lambda/ssm_execute/index.py"

# }

# resource "null_resource" "ssm_lambda_zip_files" {
#   triggers = {
#     lambdamd5 = filemd5("${path.module}/lambda/ssm_execute/index.py")
#   }
#   provisioner "local-exec" {
#     command = <<EOT
#   cd ${path.module}/lambda/ssm_execute 
#   zip -r function.zip .
#   EOT
#   }
# }


resource "aws_lambda_function" "ssm_automation_trigger_lambda" {
  filename         = "${path.module}/lambda/ssm_execute/function.zip"
  function_name    = "ssm-eks-trigger-automation"
  role             = aws_iam_role.execute_ssm_lambda_role.arn
  handler          = "index.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/ssm_execute/function.zip")
  runtime          = "python3.6"

  environment {
    variables = {
      ssm_doc        = aws_ssm_document.eks_selinux.name
      eks_versions   = var.eks_versions_to_support
      dynamodb_table = aws_dynamodb_table.ssm_eks_selinux_table.id
      time_delta     = var.time_delta
    }
  }
}

### ============================================= ###
### DynamoDB                                      ###
### ============================================= ###
resource "aws_dynamodb_table" "ssm_eks_selinux_table" {
  name           = "ssm-eks-selinux-build"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "imageID"
  range_key      = "hsbcVersion"

  attribute {
    name = "imageID"
    type = "S"
  }

  attribute {
    name = "hsbcVersion"
    type = "N"
  }

}
### ============================================= ###
### S3 Bucket for Scripts                         ###
### ============================================= ###
resource "random_id" "bucket_hex" {

  byte_length = 8
}

resource "aws_s3_bucket" "eks_ami_artifacts_bucket" {
  bucket        = "eks-ami-artifacts-bucket-${random_id.bucket_hex.hex}"
  acl           = "private"
  force_destroy = true
  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

#### uploading files to the bucket
resource "aws_s3_bucket_object" "upload_selinux_script" {
  key                    = "scripts/selinux"
  bucket                 = aws_s3_bucket.eks_ami_artifacts_bucket.id
  source                 = "${path.module}/scripts/selinux"
  server_side_encryption = "AES256"
  etag                   = filemd5("${path.module}/scripts/selinux")
}

resource "aws_s3_bucket_object" "upload_cis1_script" {
  key                    = "scripts/cis-level1"
  bucket                 = aws_s3_bucket.eks_ami_artifacts_bucket.id
  source                 = "${path.module}/scripts/cis-level1"
  server_side_encryption = "AES256"
  etag                   = filemd5("${path.module}/scripts/cis-level1")
}

resource "aws_s3_bucket_object" "upload_cluster_autoscaler_module" {
  key                    = "scripts/cis-level1"
  bucket                 = aws_s3_bucket.eks_ami_artifacts_bucket.id
  source                 = "${path.module}/scripts/cluster-autoscaler.pp"
  server_side_encryption = "AES256"
  etag                   = filemd5("${path.module}/scripts/cluster-autoscaler.pp")
}

resource "aws_s3_bucket_policy" "policy_eks_ami_artifacts_bucket" {
  bucket = aws_s3_bucket.eks_ami_artifacts_bucket.id

  policy = data.aws_iam_policy_document.policy_definition_eks_ami_artifacts_bucket.json
}

data "aws_iam_policy_document" "policy_definition_eks_ami_artifacts_bucket" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [var.eks_ami_artifacts_bucket_admin]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      "${aws_s3_bucket.eks_ami_artifacts_bucket.arn}",
      "${aws_s3_bucket.eks_ami_artifacts_bucket.arn}/*"
    ]
  }

  statement {
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.ssm_build_automation_role.arn,
        aws_iam_role.ssm_build_instance_role.arn
      ]
    }

    actions = [
      "s3:PutObject",
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.eks_ami_artifacts_bucket.arn}",
      "${aws_s3_bucket.eks_ami_artifacts_bucket.arn}/*"
    ]
  }
}


