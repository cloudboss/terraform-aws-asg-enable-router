output "event_rule" {
  description = "EventBridge rule object."
  value       = aws_cloudwatch_event_rule.it
}

output "iam_policy" {
  description = "IAM policy object."
  value       = module.iam_role.policy
}

output "iam_role" {
  description = "IAM role object."
  value       = module.iam_role.role
}

output "lambda" {
  description = "Lambda function object."
  value       = aws_lambda_function.it
}
