variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "service_name" {
  description = "Base name for resources"
  type        = string
  default     = "congenial"
}

variable "orders_zip" {
  description = "Path to orders lambda zip"
  type        = string
}

variable "inventory_zip" {
  description = "Path to inventory lambda zip"
  type        = string
}
