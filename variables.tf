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

variable "parent_pool_cidr_block" {
  description = "Account Level IPAM CIDR Block"
  type        = string
  validation {
    condition     = can(cidrsubnet(var.parent_pool_cidr_block, 0, 0))
    error_message = "CIDR block is not valid, please use CIDR notation, e.g. 10.0.0.0/8"
  }
}

variable "network_config" {
  description = "Network Configuration"
  type = object(
    {
      vpcs = map(object({
        public_subnets       = number
        private_subnets      = number
        vpc_cidr_subnet_mask = number
        subnet_mask          = number
        gw_services = object({
          igw_is_enabled               = bool
          nat_gw_is_enabled            = bool
          nat_gw_type                  = string
          nat_gw_ha                    = bool
          vpc_gateway_services         = list(string)
          vpc_interface_services       = list(string)
          vpc_interface_services_scope = string
        })
        public_subnet_nacl_rules = list(object({
          rule_number = number
          egress      = bool
          action      = string
          protocol    = string
          from_port   = number
          to_port     = number
          cidr_block  = string
        }))
        private_subnet_nacl_rules = list(object({
          rule_number = number
          egress      = bool
          action      = string
          protocol    = string
          from_port   = number
          to_port     = number
          cidr_block  = string
        }))
        tgw_config = object({
          route_destinations = list(string)
        })
      }))
      transit_gw = object({
        tgw_is_enabled = bool
        tgw_vpc_attach = list(string)
        tgw_routes = list(object({
          destination    = string
          vpc_attachment = string
        }))
      })
  })
}