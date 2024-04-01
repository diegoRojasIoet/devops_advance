resource "aws_lambda_function" "handler" {
  function_name    = "handler"
  role             = aws_iam_role.role.arn
  filename         = "main.zip"
  handler          = "main.handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.9"
  timeout          = 30
  tags             = local.tags

}

resource "aws_iam_role" "role" {
  name               = "access-key-generator-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy" "permissions" {
  name   = "access-key-generator-policy"
  role   = aws_iam_role.role.id
  policy = data.aws_iam_policy_document.permissions.json
}

resource "aws_iam_user" "user" {
  name = "testuser"
  path = "/system/"
  tags = local.tags
}

resource "aws_lambda_permission" "permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handler.function_name
  principal     = "events.amazonaws.com"
}
