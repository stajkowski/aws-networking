locals {
  project_name           = "projecta"
  environment            = "test"
  parent_pool_cidr_block = "10.0.0.0/8"
  ipam_scope_id          = null
  network_config = {
    "test" = {
      vpcs = {
        "webapp" = {
          public_subnets             = 2
          private_subnets            = 2
          vpc_cidr_subnet_mask       = 16
          subnet_mask                = 24
          additional_private_subnets = {
            "db" = {
              subnet_count = 2
              nacl_rules = [
                {
                  rule_number = 10
                  egress      = false
                  action      = "allow"
                  protocol    = 6
                  cidr_block  = "webapp"
                  from_port   = 3306
                  to_port     = 3306
                },
                { # Rule aonly allows return traffic from Webapp VPC
                  rule_number = 20
                  egress      = false
                  action      = "allow"
                  protocol    = 6
                  cidr_block  = "webapp"
                  from_port   = 1024
                  to_port     = 65535
                },
                {
                  rule_number = 10
                  egress      = true
                  action      = "allow"
                  protocol    = -1
                  cidr_block  = "webapp"
                  from_port   = 0
                  to_port     = 0
                }
              ]
            }
          }
          public_subnet_nacl_rules = [
            {
              rule_number = 10
              egress      = false
              action      = "allow"
              protocol    = 6
              cidr_block  = "0.0.0.0/0"
              from_port   = 443
              to_port     = 443
            },
            {
              rule_number = 20
              egress      = false
              action      = "allow"
              protocol    = 6
              cidr_block  = "0.0.0.0/0"
              from_port   = 80
              to_port     = 80
            },
            {
              rule_number = 10
              egress      = true
              action      = "allow"
              protocol    = -1
              cidr_block  = "0.0.0.0/0"
              from_port   = 0
              to_port     = 0
            }
          ]
          private_subnet_nacl_rules = [
            {
              rule_number = 10
              egress      = false
              action      = "allow"
              protocol    = 6
              cidr_block  = "webapp"
              from_port   = 443
              to_port     = 443
            },
            {
              rule_number = 20
              egress      = false
              action      = "allow"
              protocol    = 6
              cidr_block  = "ipam_account_pool"
              from_port   = 22
              to_port     = 22
            },
            { # Rule allows NAT GW return traffic
              rule_number = 30
              egress      = false
              action      = "allow"
              protocol    = 6
              cidr_block  = "0.0.0.0/0"
              from_port   = 1024
              to_port     = 65535
            },
            {
              rule_number = 10
              egress      = true
              action      = "allow"
              protocol    = -1
              cidr_block  = "0.0.0.0/0"
              from_port   = 0
              to_port     = 0
            }
          ]
          gw_services = {
            igw_is_enabled       = true
            nat_gw_is_enabled    = true
            nat_gw_type          = "public"
            nat_gw_ha            = false
            vpc_gateway_services = []
            vpc_interface_services = []
            vpc_interface_services_scope = "private"
          }
          tgw_config = {
            route_destinations = []
          }
        }
      }
      transit_gw = {
        tgw_is_enabled = false
        tgw_vpc_attach = []
        tgw_routes = []
      }
      internet_monitor = {
        is_enabled                    = false
        monitor_vpcs                  = []
        traffic_percentage_to_monitor = 50
        max_city_networks_to_monitor  = 100
        availability_threshold        = 96
        performance_threshold         = 96
        status                        = "ACTIVE"
        alarm_config = {
          sns_topics = {}
          sns_subscriptions = []
          alarms = {}
        }
      }
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

module "aws-networking" {
  source                 = "../../"
  project_name           = local.project_name
  environment            = local.environment
  parent_pool_cidr_block = local.parent_pool_cidr_block
  ipam_scope_id          = local.ipam_scope_id
  network_config         = local.network_config[local.environment]
}