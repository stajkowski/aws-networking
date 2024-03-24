mock_provider "aws" {}

variables {
  project_name = "projecta"
  environment  = "test"
  vpc_name     = "infra1"
  vpcs = {
    "egress" = {
      vpc_id             = "vpc-apwiefunawg"
      private_subnet_ids = ["sub1", "sub2"]
      public_subnet_ids  = ["sub3", "sub4"]
      additional_private_subnet_ids = ["sub5", "sub6"]
    }
    "infra1" = {
      vpc_id             = "vpc-aaweoiuna9weg"
      private_subnet_ids = ["sub5", "sub6"]
      public_subnet_ids  = ["sub7", "sub8"]
      additional_private_subnet_ids = ["sub5", "sub6"]
    }
  }
  route_table_routes = [
    {
      route_table_id = "rt1"
      destination    = "0.0.0.0/0"
    },
    {
      route_table_id = "rt2"
      destination    = "0.0.0.0/0"
    }
  ]
  tgw_vpc_attach = ["infra1", "egress"]
  tgw_routes = [
    {
      "destination"    = "0.0.0.0/0"
      "vpc_attachment" = "egress"
    }
  ]
}

run "positive_standard_config" {
  command = plan

  assert {
    condition     = length(aws_ec2_transit_gateway_vpc_attachment.transit_gateway) == 2
    error_message = "Expected 2 Transit Gateway Attachments"
  }

}

run "positive_standard_config_route_table_routes" {
  command = plan

  assert {
    condition     = length(aws_route.tgw_route) == 2
    error_message = "Expected 2 Route Table Updates"
  }

}

run "positive_tgw_routes" {
  command = plan

  assert {
    condition     = length(aws_ec2_transit_gateway_route.tgw_route_table_routes) == 1
    error_message = "Expected 1 Additional TGW Route"
  }

}

run "positive_named_tgw_routes" {
  command = plan

  variables {
    tgw_routes = [
      {
        "destination"    = "infra1"
        "vpc_attachment" = "egress"
      },
      {
        "destination"    = "0.0.0.0/0"
        "vpc_attachment" = "egress"
      }
    ]
  }

  expect_failures = [
    aws_ec2_transit_gateway_route.tgw_route_table_routes
  ]

}

run "nagative_invalid_route_tgw_routes" {
  command = plan

  variables {
    tgw_routes = [
      {
        "destination"    = "10.0.0.0/-1"
        "vpc_attachment" = "egress"
      },
      {
        "destination"    = "0.0.0.0/0"
        "vpc_attachment" = "egress"
      }
    ]
  }

  expect_failures = [
    aws_ec2_transit_gateway_route.tgw_route_table_routes
  ]

}

run "negative_invalid_tgw_attachment" {
  command = plan

  variables {
    tgw_vpc_attach = ["inf", "egress"]
  }

  expect_failures = [
    aws_ec2_transit_gateway_vpc_attachment.transit_gateway
  ]

}

run "negative_tgw_no_routes" {
  command = plan

  variables {
    route_table_routes = []
  }

  expect_failures = [
    aws_ec2_transit_gateway.transit_gateway
  ]

}