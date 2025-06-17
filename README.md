# Congenial AWS Boilerplate

This repository provides a basic Node.js (TypeScript) project using a CQRS
pattern with two microservices (`orders` and `inventory`). It shows how you
might wire up AWS services such as API Gateway, DynamoDB, OpenSearch
(Amazon OpenSearch Service), AWS Lambda and EventBridge for communication.
Deployment configuration is managed using Terraform.

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
npm test           # placeholder test script
```

## Deployment with Terraform

Edit the variables in `terraform/variables.tf` as needed and run:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This will create DynamoDB tables, Lambda functions, API Gateway resources,
EventBridge bus and an OpenSearch domain.
