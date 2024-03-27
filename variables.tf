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

variable "ipam_scope_id" {
  description = "Override IPAM Scope ID to use for VPC/Subnet Assignment"
  type        = string
  default     = null
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
        additional_private_subnets = map(object({
          subnet_count = number
          nacl_rules = list(object({
            rule_number = number
            egress      = bool
            action      = string
            protocol    = string
            from_port   = number
            to_port     = number
            cidr_block  = string
          }))
        }))
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
      vpn = object({
        client_vpn = object({
          is_enabled = bool
          vpn_protocol = string
          vpn_port = number
          client_cidr_block = string
          vpc_connection = string
          target_network = string
          ovpn_export_path = string
        })
      })
      internet_monitor = object({
        is_enabled                    = bool
        monitor_vpcs                  = list(string)
        traffic_percentage_to_monitor = number
        max_city_networks_to_monitor  = number
        availability_threshold        = number
        performance_threshold         = number
        status                        = string
        alarm_config = object({
          sns_topics = map(object({}))
          sns_subscriptions = list(object({
            topic    = string
            protocol = string
            endpoint = string
          }))
          alarms = map(object({
            description         = string
            comparison          = string
            metric_name         = string
            namespace           = string
            statistic           = string
            period              = number
            threshold           = number
            evaluation_periods  = number
            datapoints_to_alarm = number
            actions_enabled     = bool
            treat_missing_data  = string
            alarm_actions       = list(string)
          }))
        })
      })
    }
  )
}