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

resource aws_s3_bucket frontend_bucket {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_ownership_controls" "bucket_ownership_controls" {
  bucket = aws_s3_bucket.frontend_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "acl" {
  bucket     = aws_s3_bucket.frontend_bucket.id
  acl        = "private"
  depends_on = [
    aws_s3_bucket_ownership_controls.bucket_ownership_controls,
  ]
}

# API Gateway Backend
resource "aws_api_gateway_rest_api"  "backend_apigateway" {
  name          = var.api_gateway_name
}

# #this represent a deployment stage 
# resource "aws_apigatewayv2_stage" "backend_apigateway_stage" {
#   api_id      = aws_apigatewayv2_api.backend_apigateway.id
#   name        = var.stage_name
#   auto_deploy = true
# }
# #Here im telling the gateway to forward requests to the integration endpoint which is the lambda
# #that's why i send the arn of the lambda
# resource "aws_apigatewayv2_integration" "backend_apigateway_integration" {
#   api_id               = aws_apigatewayv2_api.backend_apigateway.id
#   integration_type     = "AWS_PROXY"
#   integration_method   = "POST"
#   integration_uri      = aws_lambda_function.handler.arn
#   passthrough_behavior = "WHEN_NO_MATCH"
# }


resource "aws_iam_role" "role" {
  name               = "backend-app"
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
