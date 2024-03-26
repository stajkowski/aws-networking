# ------------------------------------------------------------------------------
# AWS CW INTERNET MONITOR MODULE
#
# 1. Create Internet Monitor
# 2. Create SNS Topics
# 3. Create SNS Subscriptions
# 4. Create CloudWatch Alarms
#
# ------------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  alarm_config = var.internet_monitor_config.is_enabled ? var.internet_monitor_config.alarm_config : {
    sns_topics        = {}
    sns_subscriptions = []
    alarms            = {}
  }
}

# Create Internet Monitor
resource "aws_internetmonitor_monitor" "internet_monitor" {
  count        = var.internet_monitor_config.is_enabled ? 1 : 0
  monitor_name = "${var.project_name}-${var.environment}-internet-monitor"
  resources = toset([
    for vpc in var.internet_monitor_config.monitor_vpcs : "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:vpc/${var.aws_vpc[vpc].vpc_id}"
  ])
  max_city_networks_to_monitor  = var.internet_monitor_config.max_city_networks_to_monitor
  traffic_percentage_to_monitor = var.internet_monitor_config.traffic_percentage_to_monitor
  health_events_config {
    availability_score_threshold = var.internet_monitor_config.availability_threshold
    performance_score_threshold  = var.internet_monitor_config.performance_threshold
  }
  status = var.internet_monitor_config.status
}

# Create SNS Topics
resource "aws_sns_topic" "sns_topics" {
  for_each = local.alarm_config.sns_topics
  name     = "${var.project_name}-${var.environment}-${each.key}"
}

# Create SNS Subscriptions
resource "aws_sns_topic_subscription" "sns_subscriptions" {
  depends_on = [aws_sns_topic.sns_topics]
  count      = length(local.alarm_config.sns_subscriptions)
  topic_arn  = aws_sns_topic.sns_topics[local.alarm_config.sns_subscriptions[count.index].topic].arn
  protocol   = local.alarm_config.sns_subscriptions[count.index].protocol
  endpoint   = local.alarm_config.sns_subscriptions[count.index].endpoint
}

# Create CloudWatch Alarms
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
    "MeasurementSource" : "AWS"
  }
  actions_enabled = each.value.actions_enabled
  alarm_actions   = [for action in each.value.alarm_actions : aws_sns_topic.sns_topics[action].arn]
}