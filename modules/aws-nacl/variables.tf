variable "vpc_name" {
  description = "VPC Name"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]*$", var.vpc_name)) && length(var.vpc_name) > 0
    error_message = "VPC name should be alphanumeric, can contain hyphens, and not be empty"
  }
}

variable "vpc_id" {
  description = "VPC ID"
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

variable "public_subnet_nacl_rules" {
  description = "Public Subnet NACL Rules"
  type = list(object({
    rule_number = number
    egress      = bool
    action      = string
    protocol    = string
    cidr_block  = string
    from_port   = number
    to_port     = number
  }))
  default = []
}

variable "private_subnet_nacl_rules" {
  description = "Private Subnet NACL Rules"
  type = list(object({
    rule_number = number
    egress      = bool
    action      = string
    protocol    = string
    cidr_block  = string
    from_port   = number
    to_port     = number
  }))
  default = []
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