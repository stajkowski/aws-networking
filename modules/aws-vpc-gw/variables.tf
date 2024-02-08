variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_name" {
  description = "VPC Name"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public Subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private Subnet IDs"
  type        = list(string)
}

variable "public_route_table_id" {
  description = "Public Route Table ID"
  type        = string
}

variable "private_route_table_ids" {
  description = "Private Route Table ID"
  type        = list(string)
}

variable "vpc_interface_security_group_id" {
  description = "VPC Endpoint Security Group ID"
  type        = string
}

variable "vpc_gateway_services" {
  description = "VPC Gateway Services"
  type        = list(string)
  default     = []
  validation {
    condition     = !contains([for service in var.vpc_gateway_services : contains(["s3", "dynamodb"], service)], false)
    error_message = "VPC Gateway Services should be either s3 or dynamodb"
  }
}

variable "vpc_interface_services" {
  description = "VPC Interface Endpoint Services"
  type        = list(string)
  default     = []
}

variable "vpc_interface_services_scope" {
  description = "VPC Interface Endpoint Services Scope"
  type        = string
  validation {
    condition     = can(regex("^(private|both)$", var.vpc_interface_services_scope))
    error_message = "VPC Interface Services Scope should be either private or both (private and public)"
  }
}

variable "igw_is_enabled" {
  description = "Internet Gateway is Enabled"
  type        = bool
}

variable "nat_gw_is_enabled" {
  description = "NAT Gateway is Enabled"
  type        = bool
}

variable "nat_gw_type" {
  description = "NAT Gateway Type"
  type        = string
  validation {
    condition     = can(regex("^(public|private)$", var.nat_gw_type))
    error_message = "NAT Gateway type should be either public or private"
  }
}

variable "project_name" {
  description = "Project Name"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]*$", var.project_name)) && length(var.project_name) > 0
    error_message = "Project name should be alphanumeric, can contain hyphens, and not be empty"
  }
}

variable "environment" {
  description = "Environment"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]*$", var.environment)) && length(var.environment) > 0
    error_message = "Environment should be alphanumeric, can contain hyphens, and not be empty"
  }
}