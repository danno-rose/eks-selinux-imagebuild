/*
Build Instance Role -- Attached to instance when building custom AMI
*/
## Role
resource "aws_iam_role" "ssm_build_instance_role" {
  name = "ssm-eks-selinux-instance-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
# Role Policy
resource "aws_iam_policy" "ssm_build_instance_role_policy" {
  name   = "ssm-eks-selinux-build-instancerole-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.ssm_build_instance_role_policy_doc.json
}
# policy definition
data "aws_iam_policy_document" "ssm_build_instance_role_policy_doc" {
  statement {
    sid    = "1"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:GetManifest",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation"
    ]
    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply"
    ]
    resources = [
      "*",
    ]
  }

}
# EC2 instance Profile
resource "aws_iam_instance_profile" "ssm_build_instance_profile" {
  name = "ssm-eks-selinux-build-instance-profile"
  role = aws_iam_role.ssm_build_instance_role.name
}

# Role Policy attachment
resource "aws_iam_role_policy_attachment" "ssm_build_instance_role_policy_attachment" {
  role       = aws_iam_role.ssm_build_instance_role.name
  policy_arn = aws_iam_policy.ssm_build_instance_role_policy.arn
}

/*
Build Automation Role -- Assumed by SSM when running automation
*/

# Role
resource "aws_iam_role" "ssm_build_automation_role" {
  name = "ssm-eks-selinux-automation-role"

  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Effect": "Allow",
    "Principal": {
      "Service": [
        "ec2.amazonaws.com",
        "ssm.amazonaws.com"
      ]
    },
    "Action": "sts:AssumeRole"
  }
]
}
EOF
}

# Role Policy
resource "aws_iam_policy" "ssm_build_automation_role_policy" {
  name   = "ssm-eks-selinux-automation-role-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.ssm_build_automation_role_policy_doc.json
}
# policy definition
data "aws_iam_policy_document" "ssm_build_automation_role_policy_doc" {
  statement {
    sid    = "1"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]

    resources = [
      "arn:aws:lambda:*:*:function:Automation*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateImage",
      "ec2:CopyImage",
      "ec2:DeregisterImage",
      "ec2:DescribeImages",
      "ec2:DeleteSnapshot",
      "ec2:StartInstances",
      "ec2:RunInstances",
      "ec2:StopInstances",
      "ec2:TerminateInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DescribeTags",
      "cloudformation:CreateStack",
      "cloudformation:DescribeStackEvents",
      "cloudformation:DescribeStacks",
      "cloudformation:UpdateStack",
      "cloudformation:DeleteStack"
    ]
    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:*"
    ]
    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      "arn:aws:sns:*:*:Automation*",
      "arn:aws:sns:*:*:scanFactory*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.ssm_build_instance_role.arn
    ]
  }
}
#Policy attach
resource "aws_iam_role_policy_attachment" "ssm_build_automation_policy_attachment" {
  role       = aws_iam_role.ssm_build_automation_role.name
  policy_arn = aws_iam_policy.ssm_build_automation_role_policy.arn
}

/*
Execute SSM Automation Role -- Assumed by Lambda when triggering automation
*/

resource "aws_iam_role" "execute_ssm_lambda_role" {
  name = "ssm-eks-ssm-automation-trigger-role"

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
# Role Policy
resource "aws_iam_policy" "execute_ssm_lambda_role_policy" {
  name   = "ssm-eks-lambda-automation-trigger"
  path   = "/"
  policy = data.aws_iam_policy_document.execute_ssm_lambda_role_policy_doc.json
}

# policy definition
data "aws_iam_policy_document" "execute_ssm_lambda_role_policy_doc" {
  statement {
    sid    = "1"
    effect = "Allow"
    actions = [
      "ssm:StartAutomationExecution",
      "ec2:DescribeImages"
    ]

    resources = [
      "*",
    ]
  }
  statement {
    sid    = "1"
    effect = "Allow"
    actions = [
      "dynamodb:readtable",
      "dynamodb:writetable" #TODO: Get the correct dynamodB permissions set
    ]

    resources = [
      aws_dynamodb_table.ssm_eks_selinux_table.arn
    ]
  }
}


#Policy attach
resource "aws_iam_role_policy_attachment" "execute_ssm_lambda_policy_attach_1" {
  role       = aws_iam_role.execute_ssm_lambda_role.name
  policy_arn = aws_iam_policy.execute_ssm_lambda_role_policy.arn
}

#Policy attach
resource "aws_iam_role_policy_attachment" "execute_ssm_lambda_policy_attach_2" {
  role       = aws_iam_role.execute_ssm_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}






