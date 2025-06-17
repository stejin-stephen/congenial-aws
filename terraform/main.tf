terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_dynamodb_table" "orders" {
  name           = "orders"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "inventory" {
  name           = "inventory"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_opensearch_domain" "search" {
  domain_name = "example-search"
  engine_version = "OpenSearch_2.3"
  cluster_config {
    instance_type = "t3.small.search"
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name = "/aws/lambda/${var.service_name}"
  retention_in_days = 14
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.service_name}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "orders" {
  function_name = "orders-handler"
  filename      = var.orders_zip
  handler       = "index.handler"
  source_code_hash = filebase64sha256(var.orders_zip)
  role          = aws_iam_role.lambda_role.arn
  runtime       = "nodejs18.x"
}

resource "aws_lambda_function" "inventory" {
  function_name = "inventory-handler"
  filename      = var.inventory_zip
  handler       = "index.handler"
  source_code_hash = filebase64sha256(var.inventory_zip)
  role          = aws_iam_role.lambda_role.arn
  runtime       = "nodejs18.x"
}

resource "aws_apigatewayv2_api" "api" {
  name          = "service-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "orders" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.orders.invoke_arn
}

resource "aws_apigatewayv2_route" "orders" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /orders"
  target    = "integrations/${aws_apigatewayv2_integration.orders.id}"
}

resource "aws_apigatewayv2_integration" "inventory" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.inventory.invoke_arn
}

resource "aws_apigatewayv2_route" "inventory" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /inventory"
  target    = "integrations/${aws_apigatewayv2_integration.inventory.id}"
}

resource "aws_eventbridge_bus" "service_bus" {
  name = "service-bus"
}

resource "aws_lambda_permission" "orders_event" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.orders.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_eventbridge_bus.service_bus.arn
}

resource "aws_lambda_permission" "inventory_event" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.inventory.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_eventbridge_bus.service_bus.arn
}

resource "aws_cloudwatch_event_rule" "order_created" {
  name        = "OrderCreatedRule"
  event_bus_name = aws_eventbridge_bus.service_bus.name
  event_pattern = jsonencode({
    detail-type = ["OrderCreated"]
  })
}

resource "aws_cloudwatch_event_target" "order_created_inventory" {
  rule      = aws_cloudwatch_event_rule.order_created.name
  event_bus_name = aws_eventbridge_bus.service_bus.name
  target_id = "InventoryHandler"
  arn       = aws_lambda_function.inventory.arn
}

resource "aws_cloudwatch_event_rule" "stock_updated" {
  name        = "StockUpdatedRule"
  event_bus_name = aws_eventbridge_bus.service_bus.name
  event_pattern = jsonencode({
    detail-type = ["StockUpdated"]
  })
}

resource "aws_cloudwatch_event_target" "stock_updated_orders" {
  rule      = aws_cloudwatch_event_rule.stock_updated.name
  event_bus_name = aws_eventbridge_bus.service_bus.name
  target_id = "OrdersHandler"
  arn       = aws_lambda_function.orders.arn
}
