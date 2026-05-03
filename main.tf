# ---------------------------
# S3 Bucket (User Uploads)
# ---------------------------
resource "aws_s3_bucket" "uploads" {
  bucket = "${var.project_name}-uploads-${var.environment}"

  force_destroy = true
}

# ---------------------------
# S3 Bucket (Artifacts)
# ---------------------------
resource "aws_s3_bucket" "artifacts" {
  bucket = var.artifact_bucket

  force_destroy = true
}

# ---------------------------
# SQS Queue (Async Processing)
# ---------------------------
resource "aws_sqs_queue" "validation_queue" {
  name = "${var.project_name}-queue"
}

# ---------------------------
# IAM Role for Lambda
# ---------------------------
resource "aws_iam_role" "lambda_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# ---------------------------
# Attach Basic Execution Policy
# ---------------------------
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------------------------
# Upload Lambda (from S3 artifact)
# ---------------------------
resource "aws_lambda_function" "upload_lambda" {
  function_name = "upload-service"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.10"

  s3_bucket = aws_s3_bucket.artifacts.id
  s3_key    = "upload.zip"

  depends_on = [aws_s3_object.upload_zip]
}

# ---------------------------
# Validator Lambda
# ---------------------------
resource "aws_lambda_function" "validator_lambda" {
  function_name = "validator-service"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.10"

  s3_bucket = aws_s3_bucket.artifacts.id
  s3_key    = "validator.zip"

  depends_on = [aws_s3_object.validator_zip]
}

# ---------------------------
# Allow S3 to Send Messages to SQS
# ---------------------------
resource "aws_sqs_queue_policy" "allow_s3" {
  queue_url = aws_sqs_queue.validation_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = "*"
      Action = "sqs:SendMessage"
      Resource = aws_sqs_queue.validation_queue.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_s3_bucket.uploads.arn
        }
      }
    }]
  })
}

# ---------------------------
# S3 → SQS Trigger
# ---------------------------
resource "aws_s3_bucket_notification" "s3_to_sqs" {
  bucket = aws_s3_bucket.uploads.id

  queue {
    queue_arn = aws_sqs_queue.validation_queue.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

# ---------------------------
# SQS → Lambda Trigger
# ---------------------------
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.validation_queue.arn
  function_name    = aws_lambda_function.validator_lambda.arn
}

# ---------------------------
# API Gateway
# ---------------------------
resource "aws_apigatewayv2_api" "api" {
  name          = "file-validation-api"
  protocol_type = "HTTP"
}

# ---------------------------
# Attach SQS Access
# ---------------------------
resource "aws_iam_role_policy_attachment" "lambda_sqs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

# ---------------------------
# API Gateway Integration
# ---------------------------
resource "aws_apigatewayv2_integration" "upload_integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.upload_lambda.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# ---------------------------
# API Route
# ---------------------------
resource "aws_apigatewayv2_route" "upload_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.upload_integration.id}"
}

# ---------------------------
# API Stage
# ---------------------------
resource "aws_apigatewayv2_stage" "dev_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

# ---------------------------
# Lambda Permission for API Gateway
# ---------------------------
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# ---------------------------
# IAM Policy: Lambda → S3 Access
# ---------------------------
resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# ---------------------------
# Upload artifacts to S3 (AUTOMATION)
# ---------------------------
resource "aws_s3_object" "upload_zip" {
  bucket = aws_s3_bucket.artifacts.id
  key    = "upload.zip"
  source = "upload.zip"
}

resource "aws_s3_object" "validator_zip" {
  bucket = aws_s3_bucket.artifacts.id
  key    = "validator.zip"
  source = "validator.zip"
}