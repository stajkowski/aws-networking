variable "internet_monitor_config" {
  description = "Internet Monitor Configuration"
  type = object({
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

variable "aws_vpc" {
  description = "Configured VPCs"
  type = map(object({
    vpc_id = string
  }))
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