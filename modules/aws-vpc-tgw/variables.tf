variable "vpcs" {
  description = "VPCs"
  type = map(
    object(
      {
        vpc_id                        = string,
        private_subnet_ids            = list(string),
        public_subnet_ids             = list(string),
        additional_private_subnet_ids = list(string)
      }
    )
  )
}

variable "route_table_routes" {
  description = "Route Table Routes"
  type = list(
    object(
      {
        destination    = string,
        route_table_id = string
      }
    )
  )
  default = []
}

variable "tgw_vpc_attach" {
  description = "Transit Gateway VPC Attachments"
  type        = list(string)
}

variable "tgw_routes" {
  description = "Added Transit Gateway Routes"
  type = list(
    object(
      {
        destination    = string,
        vpc_attachment = string
      }
    )
  )
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