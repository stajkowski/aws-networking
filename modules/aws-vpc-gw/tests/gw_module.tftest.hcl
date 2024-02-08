mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
}

variables {
  project_name            = "projecta"
  environment             = "test"
  vpc_name                = "infra1"
  vpc_id                          = "vpcid"
  public_subnet_ids               = ["sub1","sub2"]
  private_subnet_ids              = ["sub3","sub4"]
  public_route_table_id           = "rt1"
  private_route_table_ids         = ["rt1", "rt2"]
  igw_is_enabled                  = true
  nat_gw_is_enabled               = true
  nat_gw_type                     = "public"
  vpc_gateway_services            = []
  vpc_interface_services          = []
  vpc_interface_services_scope    = "both"
  vpc_interface_security_group_id = "sg1"
}

run "positive_standard_config_igw_natgw" {
  command = plan

  variables {
    private_route_table_ids         = ["rt1"]
    private_subnet_ids              = ["sub1"]
  }

  assert {
    condition     = length(aws_internet_gateway.igw) == 1 && length(aws_eip.nat_eip) == 1 && length(aws_nat_gateway.nat_gw) == 1
    error_message = "Expected 1 IGW, 1 NATGW, and 1 EIP"
  }

}

run "positive_standard_config_igw_natgw_ha" {
  command = plan

  variables {
    private_route_table_ids         = ["rt1", "rt2"]
    private_subnet_ids              = ["sub1", "sub2"]
  }

  assert {
    condition     = length(aws_internet_gateway.igw) == 1 && length(aws_eip.nat_eip) == 2 && length(aws_nat_gateway.nat_gw) == 2
    error_message = "Expected 1 IGW, 2 NATGW, and 2 EIP"
  }

}

run "positive_standard_config_no_igw_natgw_private" {
  command = plan

  variables {
    public_subnet_ids               = []
    igw_is_enabled                  = false
    nat_gw_is_enabled               = true
    nat_gw_type                     = "private"
  }

  assert {
    condition     = length(aws_internet_gateway.igw) == 0 && length(aws_eip.nat_eip) == 0 && length(aws_nat_gateway.nat_gw) == 2
    error_message = "Expected 0 IGW, 0 EIP, and 1 NATGW"
  }

}

run "positive_standard_config_vpcgw" {
  command = plan

  variables {
    vpc_gateway_services            = ["s3"]
  }

  assert {
    condition     = length(aws_vpc_endpoint.vpc_gateway_endpoint) == 1
    error_message = "Expected VPC GW Service"
  }

}

run "positive_standard_config_vpcgw_service_name" {
  command = plan

  variables {
    vpc_gateway_services            = ["s3"]
  }

  assert {
    condition     = aws_vpc_endpoint.vpc_gateway_endpoint["s3"].service_name == "com.amazonaws.us-east-1.s3"
    error_message = "Expected Service Name com.amazonaws.us-east-1.s3"
  }

}

run "positive_standard_config_interface_endpoints_private" {
  command = plan

  variables {
    vpc_interface_services_scope    = "private"
    vpc_interface_services          = ["sts"]
  }

  assert {
    condition     = length(aws_vpc_endpoint.vpc_interface_endpoint) == 1 && length(aws_vpc_endpoint.vpc_interface_endpoint["sts"].subnet_ids) == 2
    error_message = "Expected VPC GW Service with 2 Private Subnets Assigned"
  }

}

run "positive_standard_config_interface_endpoints_private_service_name" {
  command = plan

  variables {
    vpc_interface_services_scope    = "private"
    vpc_interface_services          = ["sts"]
  }

  assert {
    condition     = aws_vpc_endpoint.vpc_interface_endpoint["sts"].service_name == "com.amazonaws.us-east-1.sts"
    error_message = "Expected Interface Endpoint Service Name com.amazonaws.us-east-1.sts"
  }

}

run "positive_standard_config_interface_endpoints_both" {
  command = plan

  variables {
    vpc_interface_services_scope    = "both"
    vpc_interface_services          = ["sts"]
  }

  assert {
    condition     = length(aws_vpc_endpoint.vpc_interface_endpoint) == 1 && length(aws_vpc_endpoint.vpc_interface_endpoint["sts"].subnet_ids) == 4
    error_message = "Expected VPC GW Service with 4 Subnets Assigned"
  }

}

run "negative_igw_no_public_subnets" {
  command = plan

  variables {
    public_subnet_ids               = []
    nat_gw_is_enabled               = false
  }

  expect_failures = [
    aws_internet_gateway.igw
  ]

}

run "negative_natgw_public_no_public_subnets" {
  command = plan

  variables {
    public_subnet_ids               = []
    igw_is_enabled                  = false
  }

  expect_failures = [
    aws_eip.nat_eip
  ]

}

run "negative_natgw_public_public_subnets_no_igw" {
  command = plan

  variables {
    public_subnet_ids               = ["sub1","sub2"]
    igw_is_enabled                  = false
  }

  expect_failures = [
    aws_eip.nat_eip
  ]

}