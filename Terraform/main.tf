locals {
  common_tags = {
    Name        = "CFN_Termination_Protection"
    CreatedFrom = "Terraform"
    description = "Kenny Medium Article"
  }
  region_account_id = "${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}"
}


resource "aws_iam_role" "Lambda_Function_Role" {
  name = "Lambda_Function_Role_CFN_TP"
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "Lambda_Function_Role_InlinePolicy" {
  name = "CFN_Stack_TP_InlinePolicy"
  role = aws_iam_role.Lambda_Function_Role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:${local.region_account_id}:log-group:/aws/lambda/${var.LambdaFunctionName}:*"
      },
      {
        "Sid" : "AllowedCloudformationActions",
        "Effect" : "Allow",
        "Action" : [
          "cloudformation:ListStacks",
          "cloudformation:UpdateTerminationProtection",
          "cloudformation:DescribeStacks"
        ],
        "Resource" : "arn:aws:cloudformation:${local.region_account_id}:stack/*"
      }
    ]
  })
}

resource "aws_iam_role" "ScheduleIAMRole" {
  name = "EventBridge_Scheduler_Lambda_TP"
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "ScheduleIAMRole_InlinePolicy" {
  name = "my_inline_policy"
  role = aws_iam_role.ScheduleIAMRole.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:InvokeFunction"
        ],
        "Resource" : "arn:aws:lambda:${local.region_account_id}:function:${var.LambdaFunctionName}"
      }
    ]
  })
}

resource "aws_lambda_function" "my_lambda_function" {
  # If the file is not in the current working directory you will need to include a path.module in the filename.
  filename      = "cloudformation_TP.zip"
  function_name = var.LambdaFunctionName
  description   = "Enforce Termination Protection on CloudFormation Stack"
  role          = aws_iam_role.Lambda_Function_Role.arn
  handler       = "cloudformation_TP.lambda_handler"
  timeout       = 300
  runtime       = "python3.12"
}

resource "aws_scheduler_schedule" "my_scheduler_schedule" {
  name       = "Daily_Invoke_CFN_TP"
  group_name = "default"
  flexible_time_window {
    mode = "OFF"
  }
  schedule_expression          = "cron(0 15 * * ? *)"
  schedule_expression_timezone = "Asia/Singapore"
  target {
    arn      = aws_lambda_function.my_lambda_function.arn
    role_arn = aws_iam_role.ScheduleIAMRole.arn
    input = jsonencode(
      {
        "source" : "aws.eventbridge_scheduler_schedules_CFN_TerminationProtection"
      }
    )
  }
  # tags = local.common_tags # An argument named "tags" is not expected here.
}


resource "aws_cloudwatch_event_rule" "event_bridge_rule" {
  name        = "CloudFormation-stack-creation"
  description = "Capture each CloudFormation stack creation"
  event_pattern = jsonencode({
    "source" : ["aws.cloudformation"],
    "detail-type" : ["CloudFormation Stack Status Change"],
    "detail" : {
      "status-details" : {
        "status" : ["CREATE_IN_PROGRESS"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.event_bridge_rule.name
  target_id = "InvokeLambda"
  arn       = aws_lambda_function.my_lambda_function.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.event_bridge_rule.arn
}
