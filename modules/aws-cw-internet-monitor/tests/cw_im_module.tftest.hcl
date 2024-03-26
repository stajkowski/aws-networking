mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-west-2"
    }
  }
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "511111111111"
    }
  }
}

variables {
  project_name = "projecta"
  environment  = "test"
  aws_vpc = {
    "egress" = {
      vpc_id = "vpc-egressid"
    }
  }
  internet_monitor_config = {
    is_enabled                    = true
    monitor_vpcs                  = ["egress"]
    traffic_percentage_to_monitor = 50
    max_city_networks_to_monitor  = 100
    availability_threshold        = 96
    performance_threshold         = 96
    status                        = "ACTIVE"
    alarm_config = {
      sns_topics = {
        "egress-alarms" = {}
      }
      sns_subscriptions = [
        {
          topic    = "egress-alarms"
          protocol = "email"
          endpoint = "infra-alerts@example.com"
        }
      ]
      alarms = {
        "egress-availability-score" = {
          description         = "AWS Iternet Monitor Egress availability score less than 96 for 5m."
          comparison          = "LessThanThreshold"
          metric_name         = "AvailabilityScore"
          namespace           = "AWS/InternetMonitor"
          statistic           = "Average"
          period              = 300
          threshold           = 96
          evaluation_periods  = 2
          datapoints_to_alarm = 2
          actions_enabled     = true
          treat_missing_data  = "missing"
          alarm_actions = [
            "egress-alarms"
          ]
        }
        "egress-performance-score" = {
          description         = "AWS Iternet Monitor Egress performance score less than 96 for 5m."
          comparison          = "LessThanThreshold"
          metric_name         = "PerformanceScore"
          namespace           = "AWS/InternetMonitor"
          statistic           = "Average"
          period              = 300
          threshold           = 96
          evaluation_periods  = 2
          datapoints_to_alarm = 2
          actions_enabled     = true
          treat_missing_data  = "missing"
          alarm_actions = [
            "egress-alarms"
          ]
        }
      }
    }
  }
}

run "positive_standard_config" {
  command = plan

  assert {
    condition     = length(aws_internetmonitor_monitor.internet_monitor) == 1
    error_message = "Expected 1 Internet Monitor Configured."
  }

}

run "positive_standard_config_sns" {
  command = plan

  assert {
    condition     = contains(keys(aws_sns_topic.sns_topics), "egress-alarms") && length(aws_sns_topic_subscription.sns_subscriptions) == 1
    error_message = "Expected SNS Topic egress-alarms and 1 subscription."
  }

}

run "positive_standard_config_cw" {
  command = plan

  assert {
    condition     = contains(keys(aws_cloudwatch_metric_alarm.internet_monitor_alarms), "egress-availability-score") && contains(keys(aws_cloudwatch_metric_alarm.internet_monitor_alarms), "egress-performance-score")
    error_message = "Expected 2 CW Alarms."
  }

}

run "positive_disabled_full_config" {
  command = plan

  variables {
    internet_monitor_config = {
      is_enabled                    = false
      monitor_vpcs                  = ["egg"]
      traffic_percentage_to_monitor = 50
      max_city_networks_to_monitor  = 100
      availability_threshold        = 96
      performance_threshold         = 96
      status                        = "ACTIVE"
      alarm_config = {
        sns_topics = {
          "egress-alarms" = {}
        }
        sns_subscriptions = [
          {
            topic    = "egress-alarms"
            protocol = "email"
            endpoint = "infra-alerts@example.com"
          }
        ]
        alarms = {
          "egress-availability-score" = {
            description         = "AWS Iternet Monitor Egress availability score less than 96 for 5m."
            comparison          = "LessThanThreshold"
            metric_name         = "AvailabilityScore"
            namespace           = "AWS/InternetMonitor"
            statistic           = "Average"
            period              = 300
            threshold           = 96
            evaluation_periods  = 2
            datapoints_to_alarm = 2
            actions_enabled     = true
            treat_missing_data  = "missing"
            alarm_actions = [
              "egress-alarms"
            ]
          }
          "egress-performance-score" = {
            description         = "AWS Iternet Monitor Egress performance score less than 96 for 5m."
            comparison          = "LessThanThreshold"
            metric_name         = "PerformanceScore"
            namespace           = "AWS/InternetMonitor"
            statistic           = "Average"
            period              = 300
            threshold           = 96
            evaluation_periods  = 2
            datapoints_to_alarm = 2
            actions_enabled     = true
            treat_missing_data  = "missing"
            alarm_actions = [
              "egress-alarms"
            ]
          }
        }
      }
    }
  }

  assert {
    condition     = length(aws_internetmonitor_monitor.internet_monitor) == 0
    error_message = "Expected 0 Internet Monitor Configured."
  }

}

run "positive_disabled_no_config" {
  command = plan

  variables {
    internet_monitor_config = {
      is_enabled                    = false
      monitor_vpcs                  = []
      traffic_percentage_to_monitor = 50
      max_city_networks_to_monitor  = 100
      availability_threshold        = 96
      performance_threshold         = 96
      status                        = "ACTIVE"
      alarm_config = {
        sns_topics        = {}
        sns_subscriptions = []
        alarms            = {}
      }
    }
  }

  assert {
    condition     = length(aws_internetmonitor_monitor.internet_monitor) == 0
    error_message = "Expected 0 Internet Monitor Configured."
  }

}

run "positive_enabled_no_alarms" {
  command = plan

  variables {
    internet_monitor_config = {
      is_enabled                    = true
      monitor_vpcs                  = ["egress"]
      traffic_percentage_to_monitor = 50
      max_city_networks_to_monitor  = 100
      availability_threshold        = 96
      performance_threshold         = 96
      status                        = "ACTIVE"
      alarm_config = {
        sns_topics        = {}
        sns_subscriptions = []
        alarms            = {}
      }
    }
  }

  assert {
    condition     = length(aws_internetmonitor_monitor.internet_monitor) == 1 && !contains(keys(aws_sns_topic.sns_topics), "egress-alarms") && length(aws_sns_topic_subscription.sns_subscriptions) == 0
    error_message = "Expected 1 Internet Monitor Configured."
  }

}

run "negative_invalid_im_vpc" {
  command = plan

  variables {
    internet_monitor_config = {
      is_enabled                    = true
      monitor_vpcs                  = ["egg"]
      traffic_percentage_to_monitor = 50
      max_city_networks_to_monitor  = 100
      availability_threshold        = 96
      performance_threshold         = 96
      status                        = "ACTIVE"
      alarm_config = {
        sns_topics = {
          "egress-alarms" = {}
        }
        sns_subscriptions = [
          {
            topic    = "egress-alarms"
            protocol = "email"
            endpoint = "infra-alerts@example.com"
          }
        ]
        alarms = {
          "egress-availability-score" = {
            description         = "AWS Iternet Monitor Egress availability score less than 96 for 5m."
            comparison          = "LessThanThreshold"
            metric_name         = "AvailabilityScore"
            namespace           = "AWS/InternetMonitor"
            statistic           = "Average"
            period              = 300
            threshold           = 96
            evaluation_periods  = 2
            datapoints_to_alarm = 2
            actions_enabled     = true
            treat_missing_data  = "missing"
            alarm_actions = [
              "egress-alarms"
            ]
          }
          "egress-performance-score" = {
            description         = "AWS Iternet Monitor Egress performance score less than 96 for 5m."
            comparison          = "LessThanThreshold"
            metric_name         = "PerformanceScore"
            namespace           = "AWS/InternetMonitor"
            statistic           = "Average"
            period              = 300
            threshold           = 96
            evaluation_periods  = 2
            datapoints_to_alarm = 2
            actions_enabled     = true
            treat_missing_data  = "missing"
            alarm_actions = [
              "egress-alarms"
            ]
          }
        }
      }
    }
  }

  expect_failures = [
    aws_internetmonitor_monitor.internet_monitor
  ]

}