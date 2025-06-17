output "api_url" {
  description = "REST API invoke URL"
  value       = aws_api_gateway_stage.prod.invoke_url
}
