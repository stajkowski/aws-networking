variable "vpc_name" {
  description = "VPC Name"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]*$", var.vpc_name)) && length(var.vpc_name) > 0
    error_message = "VPC name should be alphanumeric, can contain hyphens, and not be empty"
  }
}

variable "acct_ipam_scope_id" {
  description = "Account IPAM Scope ID"
  type        = string
}

variable "acct_ipam_pool_id" {
  description = "Account IPAM Pool ID"
  type        = string
}

variable "acct_ipam_pool_cidr" {
  description = "Account IPAM Pool CIDR"
  type        = string
  validation {
    condition     = can(cidrsubnet(var.acct_ipam_pool_cidr, 0, 0))
    error_message = "Account IPAM CIDR should be a valid CIDR block"
  }
}

variable "vpc_cidr_subnet_mask" {
  description = "VPC CIDR Subnet Mask"
  type        = number
}

variable "subnet_mask" {
  description = "Subnet Mask for Private and Public Subnets"
  type        = number
}

variable "public_subnets" {
  description = "Number of Public Subnets to Create"
  type        = number
  validation {
    condition     = var.public_subnets >= 0
    error_message = "Public subnets should be greater than 0"
  }
}

variable "private_subnets" {
  description = "Number of Private Subnets to Create"
  type        = number
  validation {
    condition     = var.private_subnets >= 0
    error_message = "Private subnets should be greater than 0"
  }
}

variable "route_table_per_private" {
  description = "Route Table per Private Subnet"
  type        = bool
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