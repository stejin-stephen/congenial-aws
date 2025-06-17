# Congenial AWS Boilerplate

This repository provides a basic Node.js (TypeScript) project using a CQRS
pattern with two microservices (`orders` and `inventory`). It shows how you
might wire up AWS services such as API Gateway, DynamoDB, OpenSearch
(Amazon OpenSearch Service), AWS Lambda and EventBridge for communication.
Deployment configuration is managed using Terraform.

Orders are stored in DynamoDB via the orders command service. The table has
streaming enabled so that a separate Lambda function keeps an OpenSearch index
in sync. Queries can then use the search domain as the read model.

## Structure

- `src/` – TypeScript source files
  - `orders` – command and query handlers for order management
  - `inventory` – command and query handlers for inventory management
  - `shared` – shared utilities such as an event bus interface
- `terraform/` – sample Terraform configuration

## Commands

```bash
npm install        # install dependencies
npm run build      # compile TypeScript
npm run package    # build and create Lambda deployment zips
npm test           # placeholder test script
```

## Deployment with Terraform

Edit the variables in `terraform/variables.tf` as needed and run:

```bash
cd terraform
terraform init
terraform plan
terraform apply \
  -var="orders_zip=../orders.zip" \
  -var="inventory_zip=../inventory.zip" \
  -var="orders_stream_zip=../orders-stream.zip"
```

This will create DynamoDB tables, Lambda functions, API Gateway resources,
EventBridge bus and an OpenSearch domain.

The stream-processing function expects the `OPENSEARCH_ENDPOINT` environment
variable to point to the OpenSearch domain endpoint. Terraform sets this value
automatically from the created domain.
