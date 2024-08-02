locals {
  aws_account_id = data.aws_caller_identity.me.account_id

  aws_region = data.aws_region.here.name

  function_archive = "${path.module}/function.zip"

  iam_policy_statement_base = [
    {
      Action = [
        "logs:CreateLogGroup",
      ]
      Effect   = "Allow"
      Resource = ["arn:aws:logs:${local.aws_region}:${local.aws_account_id}:*"]
    },
    {
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
      Effect   = "Allow"
      Resource = ["arn:aws:logs:${local.aws_region}:${local.aws_account_id}:log-group:/aws/lambda/${var.name}:*"]
    },
    {
      Action = [
        "ec2:ModifyInstanceAttribute",
      ]
      Effect   = "Allow"
      Resource = ["*"]
    },
  ]

  iam_policy_statement_vpc = (
    var.vpc_config == null
    ? []
    : [
      {
        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:AttachNetworkInterface",
        ]
        Effect   = "Allow"
        Resource = ["*"]
      },
    ]
  )

  iam_policy_statements = concat(
    local.iam_policy_statement_base,
    local.iam_policy_statement_vpc,
  )

  security_group_id = one(aws_security_group.it[*].id)
}

data "aws_caller_identity" "me" {}

data "aws_region" "here" {}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/src/main.py"
  output_path = local.function_archive
}

resource "aws_security_group" "it" {
  count = var.vpc_config == null ? 0 : 1

  name   = var.name
  tags   = var.tags
  vpc_id = var.vpc_config.id
}

module "security_group_rules" {
  source  = "cloudboss/security-group-rules/aws"
  version = "0.1.0"
  count   = var.vpc_config == null ? 0 : 1

  mapping = {}
  rules = [
    {
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 443
      ip_protocol = "tcp"
      to_port     = 443
      type        = "egress"
    },
  ]
  security_group_id = local.security_group_id
  tags              = var.tags
}

module "iam_role" {
  source  = "cloudboss/iam-role/aws"
  version = "0.1.0"

  trust_policy_statements = [
    {
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    },
  ]
  name                 = var.name
  permissions_boundary = var.iam_permissions_boundary
  policy_statements    = local.iam_policy_statements
  tags                 = var.tags
}

resource "aws_lambda_function" "it" {
  filename         = local.function_archive
  function_name    = var.name
  handler          = "main.handler"
  memory_size      = var.memory_size
  role             = module.iam_role.role.arn
  runtime          = var.runtime
  source_code_hash = data.archive_file.lambda.output_base64sha256
  tags             = var.tags
  timeout          = 15

  dynamic "vpc_config" {
    for_each = var.vpc_config == null ? [] : [1]
    content {
      security_group_ids = [local.security_group_id]
      subnet_ids         = var.vpc_config.subnet_ids
    }
  }
}

resource "aws_cloudwatch_event_rule" "it" {
  name        = var.name
  description = "Trigger on instance launch for ${var.autoscaling_group_name} autoscaling group"
  event_pattern = jsonencode({
    source      = ["aws.autoscaling"]
    detail-type = ["EC2 Instance Launch Successful"]
    detail = {
      AutoScalingGroupName = [var.autoscaling_group_name]
    }
  })
}

resource "aws_cloudwatch_event_target" "it" {
  target_id = var.name
  rule      = aws_cloudwatch_event_rule.it.name
  arn       = aws_lambda_function.it.arn
}

resource "aws_lambda_permission" "it" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.it.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.it.arn
}
