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
  stream_enabled = true
  stream_view_type = "NEW_IMAGE"
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
  ebs_options {
    ebs_enabled = true
    volume_size = 10
    volume_type = "gp3"
  }
}

resource "aws_opensearch_domain_policy" "search" {
  domain_name = aws_opensearch_domain.search.domain_name
  access_policies = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { AWS = aws_iam_role.lambda_role.arn },
      Action = "es:*",
      Resource = "${aws_opensearch_domain.search.arn}/*"
    }]
  })
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

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${var.service_name}-lambda-dynamodb"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:GetRecords",
        "dynamodb:GetShardIterator",
        "dynamodb:DescribeStream",
        "dynamodb:ListStreams"
      ],
      Resource = [
        aws_dynamodb_table.orders.arn,
        aws_dynamodb_table.inventory.arn,
        aws_dynamodb_table.orders.stream_arn
      ]
    }]
  })
}

resource "aws_iam_role_policy" "lambda_opensearch" {
  name = "${var.service_name}-lambda-opensearch"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["es:ESHttp*"],
      Resource = "${aws_opensearch_domain.search.arn}/*"
    }]
  })
}

resource "aws_lambda_function" "orders" {
  function_name = "orders-handler"
  filename      = var.orders_zip
  handler       = "dist/orders/handler.handler"
  source_code_hash = filebase64sha256(var.orders_zip)
  role          = aws_iam_role.lambda_role.arn
  runtime       = "nodejs22.x"
  environment {
    variables = {
      ORDERS_TABLE = aws_dynamodb_table.orders.name
    }
  }
}

resource "aws_lambda_function" "inventory" {
  function_name = "inventory-handler"
  filename      = var.inventory_zip
  handler       = "dist/inventory/handler.handler"
  source_code_hash = filebase64sha256(var.inventory_zip)
  role          = aws_iam_role.lambda_role.arn
  runtime       = "nodejs22.x"
}

resource "aws_lambda_function" "orders_stream" {
  function_name = "orders-stream-handler"
  filename      = var.orders_stream_zip
  handler       = "dist/orders/streams/syncToSearch.handler"
  source_code_hash = filebase64sha256(var.orders_stream_zip)
  role          = aws_iam_role.lambda_role.arn
  runtime       = "nodejs22.x"
  environment {
    variables = {
      ORDERS_INDEX        = "orders"
      OPENSEARCH_ENDPOINT = aws_opensearch_domain.search.endpoint
    }
  }
}

resource "aws_lambda_event_source_mapping" "orders_stream" {
  event_source_arn = aws_dynamodb_table.orders.stream_arn
  function_name    = aws_lambda_function.orders_stream.arn
  starting_position = "LATEST"
}

resource "aws_api_gateway_rest_api" "api" {
  name = "service-api"
}

resource "aws_api_gateway_resource" "orders" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "orders"
}

resource "aws_api_gateway_method" "orders_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "orders_post" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.orders.id
  http_method             = aws_api_gateway_method.orders_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.orders.invoke_arn
}

resource "aws_lambda_permission" "orders_api" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.orders.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/POST/orders"
}

resource "aws_api_gateway_resource" "inventory" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "inventory"
}

resource "aws_api_gateway_method" "inventory_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.inventory.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "inventory_post" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.inventory.id
  http_method             = aws_api_gateway_method.inventory_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.inventory.invoke_arn
}

resource "aws_lambda_permission" "inventory_api" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.inventory.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/POST/inventory"
}

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  depends_on  = [
    aws_api_gateway_integration.orders_post,
    aws_api_gateway_integration.inventory_post
  ]
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api.id
  stage_name = "prod"
}

resource "aws_cloudwatch_event_bus" "service_bus" {
  name = "service-bus"
}

resource "aws_lambda_permission" "orders_event" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.orders.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_bus.service_bus.arn
}

resource "aws_lambda_permission" "inventory_event" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.inventory.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_bus.service_bus.arn
}

resource "aws_cloudwatch_event_rule" "order_created" {
  name        = "OrderCreatedRule"
  event_bus_name = aws_cloudwatch_event_bus.service_bus.name
  event_pattern = jsonencode({
    detail-type = ["OrderCreated"]
  })
}

resource "aws_cloudwatch_event_target" "order_created_inventory" {
  rule      = aws_cloudwatch_event_rule.order_created.name
  event_bus_name = aws_cloudwatch_event_bus.service_bus.name
  target_id = "InventoryHandler"
  arn       = aws_lambda_function.inventory.arn
}

resource "aws_cloudwatch_event_rule" "stock_updated" {
  name        = "StockUpdatedRule"
  event_bus_name = aws_cloudwatch_event_bus.service_bus.name
  event_pattern = jsonencode({
    detail-type = ["StockUpdated"]
  })
}

resource "aws_cloudwatch_event_target" "stock_updated_orders" {
  rule      = aws_cloudwatch_event_rule.stock_updated.name
  event_bus_name = aws_cloudwatch_event_bus.service_bus.name
  target_id = "OrdersHandler"
  arn       = aws_lambda_function.orders.arn
}
