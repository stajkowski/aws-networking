# ---------------------------------------------------------------------------------------------------------------------
# AWS NETWORKING MODULE
#
# Purpose: This module is used to create various AWS networking services within a VPC or a set of VPCs.  The module
# attempts to provide some flexibility in confirguration by allowing dynamic creation of public/private subnets. 
# VPC can be created with or without public subnets, NAT GW, IGW or Transit GW attachment.  Please note that if a
# public NAT GW is created, there must be a public subnet to attach it to.
#
# 1. Create VPC, Public/Private Subnets, Route Tables, and Default Security Group
# 2. Create NACLs for VPCs
# 3. Create Internet Gateway, NAT Gateway, VPCE Gateway, or VPC Interface Endpoints
# 4. Create Transit Gateway, Attach VPCs, and update VPC Route Tables
# 5. Create Internet Monitor
#
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Create Account IPAM Pool
module "aws-acct-ipam" {
  source                 = "./modules/aws-acct-ipam"
  project_name           = var.project_name
  environment            = var.environment
  parent_pool_cidr_block = var.parent_pool_cidr_block
  ipam_scope_id          = var.ipam_scope_id
}

# Create VPC with Public and Private Subnets
module "aws-vpc" {
  source                  = "./modules/aws-vpc"
  depends_on              = [module.aws-acct-ipam]
  for_each                = var.network_config.vpcs
  project_name            = var.project_name
  environment             = var.environment
  vpc_name                = each.key
  acct_ipam_scope_id      = module.aws-acct-ipam.acct_ipam_scope_id
  acct_ipam_pool_id       = module.aws-acct-ipam.acct_ipam_pool_id
  acct_ipam_pool_cidr     = var.parent_pool_cidr_block
  public_subnets          = each.value.public_subnets
  private_subnets         = each.value.private_subnets
  route_table_per_private = each.value.gw_services.nat_gw_ha
  vpc_cidr_subnet_mask    = each.value.vpc_cidr_subnet_mask
  subnet_mask             = each.value.subnet_mask
  # Additional private subnets will encode a format that informs the:
  # 1. Subnet Group
  # 2. Subnet Index
  # 3. Subnet Count for Group
  additional_private_subnets = flatten([
    for k, v in each.value.additional_private_subnets : [
      for i in range(v.subnet_count) : [
        "${k}::${i + 1}::${i}"
      ]
    ]
  ])
}

# Create NACLs for VPCs
module "aws-nacl" {
  source                        = "./modules/aws-nacl"
  depends_on                    = [module.aws-vpc]
  for_each                      = var.network_config.vpcs
  project_name                  = var.project_name
  environment                   = var.environment
  vpc_name                      = each.key
  vpc_id                        = module.aws-vpc[each.key].vpc_id
  public_subnet_ids             = module.aws-vpc[each.key].public_subnet_ids
  private_subnet_ids            = module.aws-vpc[each.key].private_subnet_ids
  additional_private_subnet_ids = module.aws-vpc[each.key].additional_private_subnet_ids
  additional_private_subnet_associations = flatten([
    for k, v in module.aws-vpc[each.key].additional_private_subnet_ids : [
      for sn in v : {
        subnet_id    = sn
        subnet_group = k
      }
    ]
  ])
  public_subnet_nacl_rules = [for rule in each.value.public_subnet_nacl_rules : {
    rule_number = rule.rule_number
    egress      = rule.egress
    protocol    = rule.protocol
    action      = rule.action
    cidr_block  = can(lookup(var.network_config.vpcs, rule.cidr_block)) ? module.aws-vpc[rule.cidr_block].vpc_cidr_block : replace(rule.cidr_block, "ipam_account_pool", var.parent_pool_cidr_block)
    from_port   = rule.from_port
    to_port     = rule.to_port
  }]
  private_subnet_nacl_rules = [
    for rule in each.value.private_subnet_nacl_rules : {
      rule_number = rule.rule_number
      egress      = rule.egress
      protocol    = rule.protocol
      action      = rule.action
      cidr_block  = can(lookup(var.network_config.vpcs, rule.cidr_block)) ? module.aws-vpc[rule.cidr_block].vpc_cidr_block : replace(rule.cidr_block, "ipam_account_pool", var.parent_pool_cidr_block)
      from_port   = rule.from_port
      to_port     = rule.to_port
    }
  ]
  additional_private_subnet_nacl_rules = flatten([
    for k, v in each.value.additional_private_subnets : [
      for rule in v.nacl_rules : {
        rule_number = rule.rule_number
        egress      = rule.egress
        protocol    = rule.protocol
        action      = rule.action
        cidr_block  = can(lookup(var.network_config.vpcs, rule.cidr_block)) ? module.aws-vpc[rule.cidr_block].vpc_cidr_block : replace(rule.cidr_block, "ipam_account_pool", var.parent_pool_cidr_block)
        from_port   = rule.from_port
        to_port     = rule.to_port
        subnet      = k
      }
    ]
  ])
}

# Setup IGW and NAT Gateway
module "aws-vpc-gw" {
  source             = "./modules/aws-vpc-gw"
  depends_on         = [module.aws-vpc]
  for_each           = var.network_config.vpcs
  project_name       = var.project_name
  environment        = var.environment
  vpc_name           = each.key
  vpc_id             = module.aws-vpc[each.key].vpc_id
  public_subnet_ids  = module.aws-vpc[each.key].public_subnet_ids
  private_subnet_ids = module.aws-vpc[each.key].private_subnet_ids
  additional_private_subnet_ids = flatten([
    for k, v in module.aws-vpc[each.key].additional_private_subnet_ids : [
      for sn in v : sn
    ]
  ])
  public_route_table_id           = module.aws-vpc[each.key].public_route_table_id
  private_route_table_ids         = module.aws-vpc[each.key].private_route_table_ids
  igw_is_enabled                  = each.value.gw_services.igw_is_enabled
  nat_gw_is_enabled               = each.value.gw_services.nat_gw_is_enabled
  nat_gw_type                     = each.value.gw_services.nat_gw_type
  vpc_gateway_services            = each.value.gw_services.vpc_gateway_services
  vpc_interface_services          = each.value.gw_services.vpc_interface_services
  vpc_interface_services_scope    = each.value.gw_services.vpc_interface_services_scope
  vpc_interface_security_group_id = module.aws-vpc[each.key].vpc_default_sg_id
}

# Setup Transit Gateway
module "aws-vpc-tgw" {
  source       = "./modules/aws-vpc-tgw"
  depends_on   = [module.aws-vpc-gw]
  count        = var.network_config.transit_gw.tgw_is_enabled ? 1 : 0
  project_name = var.project_name
  environment  = var.environment
  vpcs = {
    for vpc in var.network_config.transit_gw.tgw_vpc_attach : vpc => {
      vpc_id             = module.aws-vpc[vpc].vpc_id
      public_subnet_ids  = module.aws-vpc[vpc].public_subnet_ids
      private_subnet_ids = module.aws-vpc[vpc].private_subnet_ids
      additional_private_subnet_ids = flatten([
        for k, v in module.aws-vpc[vpc].additional_private_subnet_ids : [
          for sn in v : sn
        ]
      ])
    }
  }
  # Setup route table routes for a many to many relationship due to HA
  # configuration on private subnets for NAT GWs.  For each route table,
  # create a route for each destination in the destination list for the
  # vpc. Output is a list for each route table and destination.
  route_table_routes = flatten([
    for vpc in var.network_config.transit_gw.tgw_vpc_attach : [
      for route_table_id in concat(module.aws-vpc[vpc].private_route_table_ids, [module.aws-vpc[vpc].public_route_table_id]) : [
        for destination in var.network_config.vpcs[vpc].tgw_config.route_destinations : {
          route_table_id = route_table_id
          destination    = can(module.aws-vpc[destination].vpc_cidr_block) ? module.aws-vpc[destination].vpc_cidr_block : destination
        }
      ]
    ]
  ])
  tgw_routes = flatten([
    for route in var.network_config.transit_gw.tgw_routes : {
      destination    = can(module.aws-vpc[route.destination].vpc_cidr_block) ? module.aws-vpc[route.destination].vpc_cidr_block : route.destination
      vpc_attachment = route.vpc_attachment
    }
  ])
  tgw_vpc_attach = var.network_config.transit_gw.tgw_vpc_attach
}



data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  alarm_config = var.network_config.internet_monitor.is_enabled ? var.network_config.internet_monitor.alarm_config : {
    sns_topics = {}
    sns_subscriptions = []
    alarms = {}
  }
}

# Create Internet Monitor
resource "aws_internetmonitor_monitor" "internet_monitor" {
  count = var.network_config.internet_monitor.is_enabled ? 1 : 0
  depends_on = [ module.aws-vpc ]
  monitor_name = "${var.project_name}-${var.environment}-internet-monitor"
  resources = toset([
    for vpc in var.network_config.internet_monitor.monitor_vpcs : "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:vpc/${module.aws-vpc[vpc].vpc_id}"
  ])
  max_city_networks_to_monitor = var.network_config.internet_monitor.max_city_networks_to_monitor
  traffic_percentage_to_monitor = var.network_config.internet_monitor.traffic_percentage_to_monitor
  health_events_config {
    availability_score_threshold = var.network_config.internet_monitor.availability_threshold
    performance_score_threshold  = var.network_config.internet_monitor.performance_threshold
  }
  status = var.network_config.internet_monitor.status
}

# Create SNS Topics
resource "aws_sns_topic" "sns_topics" {
  for_each   = local.alarm_config.sns_topics
  name       = "${var.project_name}-${var.environment}-${each.key}"
}

# Create SNS Subscriptions
resource "aws_sns_topic_subscription" "sns_subscriptions" {
  depends_on = [aws_sns_topic.sns_topics]
  count      = length(local.alarm_config.sns_subscriptions)
  topic_arn  = aws_sns_topic.sns_topics[local.alarm_config.sns_subscriptions[count.index].topic].arn
  protocol   = local.alarm_config.sns_subscriptions[count.index].protocol
  endpoint   = local.alarm_config.sns_subscriptions[count.index].endpoint
}

resource "aws_cloudwatch_metric_alarm" "internet_monitor_alarms" {
  depends_on          = [aws_sns_topic.sns_topics, aws_internetmonitor_monitor.internet_monitor]
  for_each            = local.alarm_config.alarms
  alarm_name          = "${var.project_name}-${var.environment}-${each.key}"
  alarm_description   = each.value.description
  comparison_operator = each.value.comparison
  evaluation_periods  = each.value.evaluation_periods
  datapoints_to_alarm = each.value.datapoints_to_alarm
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  treat_missing_data  = each.value.treat_missing_data 

  dimensions = {
    "MonitorName" : aws_internetmonitor_monitor.internet_monitor[0].monitor_name
    "MeasurementSource": "AWS"
  }
  actions_enabled = each.value.actions_enabled
  alarm_actions   = [for action in each.value.alarm_actions : aws_sns_topic.sns_topics[action].arn]
}