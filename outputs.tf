output "api_url" {
  value = aws_apigatewayv2_api.api.api_endpoint
}

output "upload_bucket_name" {
  value = aws_s3_bucket.uploads.id
}

output "validation_table_name" {
  value = aws_dynamodb_table.validation_table.name
}
