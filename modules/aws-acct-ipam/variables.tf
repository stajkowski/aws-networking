variable "parent_pool_cidr_block" {
  description = "Account Level IPAM CIDR Block"
  type        = string
  validation {
    condition     = can(cidrsubnet(var.parent_pool_cidr_block, 0, 0))
    error_message = "CIDR block is not valid, please use CIDR notation, e.g. 10.0.0.0/8"
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

variable "ipam_scope_id" {
  description = "Override IPAM Scope ID to use for VPC/Subnet Assignment"
  type        = string
  default     = null
}