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
resource "aws_api_gateway_rest_api"  "backend_api" {
  name          = var.api_gateway_name
}

# Here im creating a new resource with the gateway already created 
resource "aws_api_gateway_resource" "backend_apigateway" {
  path_part   = "api_path"                                  #The name of the path the resource will be accesible <URL>/api_path
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  parent_id   = aws_api_gateway_rest_api.backend_api.root_resource_id
}

resource "aws_api_gateway_method" "api-gw-method" {
  rest_api_id   = aws_api_gateway_rest_api.backend_api.id
  resource_id   = aws_api_gateway_resource.backend_apigateway.id
  http_method   = "ANY"
  authorization = "NONE"
}

#The first proxy used in the integration
resource "aws_api_gateway_method" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  resource_id = aws_api_gateway_resource.backend_apigateway.id
  http_method = "ANY"
  authorization = "NONE"
}

#Integrate the lambda with the gateways
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  resource_id = aws_api_gateway_resource.backend_apigateway.id
  http_method = aws_api_gateway_method.proxy.http_method
  integration_http_method = "ANY"
  type = "AWS"
  uri = aws_lambda_function.handler.invoke_arn
}

resource "aws_api_gateway_method_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  resource_id = aws_api_gateway_resource.backend_apigateway.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"
}


resource "aws_api_gateway_integration_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  resource_id = aws_api_gateway_resource.backend_apigateway.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy.status_code

  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.lambda_integration
  ]
}

#The resource in charge of deploy the the gateway every time there's a change
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  stage_name = "dev"
}


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
