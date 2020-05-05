/*
Build Instance Role -- Attached to instance when building custom AMI
*/
## Role
resource "aws_iam_role" "ssm_build_instance_role" {
  name = "ssm-eks-selinux-instance-role-${random_id.random_hex.hex}"

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
  name   = "ssm-eks-selinux-build-instancerole-policy-${random_id.random_hex.hex}"
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
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = [
      "*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      var.ssm_instance_assume_role
    ]
  }

}
# EC2 instance Profile
resource "aws_iam_instance_profile" "ssm_build_instance_profile" {
  name = "ssm-eks-selinux-build-instance-profile-${random_id.random_hex.hex}"
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
  name = "ssm-eks-selinux-automation-role-${random_id.random_hex.hex}"

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
  name   = "ssm-eks-selinux-automation-role-policy-${random_id.random_hex.hex}"
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
    sid    = "ExtraEKSFunctionalTests"
    effect = "Allow"
    actions = [
      "ec2:DescribeSubnets",
      "ec2:DescribeKeyPairs",
      "ec2:DescribeVpcs",
      "ec2:CreateSecurityGroup",
      "ec2:DescribeSecurityGroups",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "autoscaling:*",
      "iam:CreateRole",
      "iam:PassRole",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:AddRoleToInstanceProfile"
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
  name = "ssm-eks-ssm-automation-trigger-role-${random_id.random_hex.hex}"

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
  name   = "ssm-eks-lambda-automation-trigger-${random_id.random_hex.hex}"
  path   = "/"
  policy = data.aws_iam_policy_document.execute_ssm_lambda_role_policy_doc.json
}

# policy definition
data "aws_iam_policy_document" "execute_ssm_lambda_role_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:StartAutomationExecution",
      "ec2:DescribeImages",
      "ssm:GetParameter"
    ]

    resources = [
      "*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem"
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






