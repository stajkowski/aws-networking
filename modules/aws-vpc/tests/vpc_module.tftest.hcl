mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["1a", "1b", "1c", "1d"]
    }
  }
}

variables {
  project_name            = "projecta"
  environment             = "test"
  vpc_name                = "infra1"
  acct_ipam_scope_id      = "ipam-awefkanewgaweg"
  acct_ipam_pool_id       = "ipam-awepfoinaerg"
  acct_ipam_pool_cidr     = "10.0.0.0/8"
  public_subnets          = 2
  private_subnets         = 2
  route_table_per_private = false
  vpc_cidr_subnet_mask    = 16
  subnet_mask             = 24
}

run "positive_standard_config" {
  command = plan

  assert {
    condition     = length(concat(aws_subnet.public_subnet, aws_subnet.public_subnet)) == 4 && length(aws_route_table.private_route_table) == 1
    error_message = "Expected 2 Public and 2 Private Subnets Created"
  }

}

run "positive_route_table_per_private" {
  command = plan

  variables {
    route_table_per_private = true
  }

  assert {
    condition     = length(aws_route_table.private_route_table) == 2
    error_message = "Expected 2 Private Route Tables"
  }

}

run "positive_no_public_subnets" {
  command = plan

  variables {
    public_subnets = 0
  }

  assert {
    condition     = length(aws_subnet.public_subnet) == 0 && length(aws_subnet.private_subnet) == 2
    error_message = "Expected 0 Public and 2 Private Subnets Created"
  }

}

run "negative_invalid_vpc_cidr_mask" {
  command = plan

  variables {
    vpc_cidr_subnet_mask = 8
    subnet_mask          = 24
  }

  expect_failures = [
    aws_vpc_ipam_pool_cidr.vpc_subnet_ipam_pool_cidr
  ]

}

run "negative_invalid_subnet_mask" {
  command = plan

  variables {
    vpc_cidr_subnet_mask = 16
    subnet_mask          = 10
  }

  expect_failures = [
    aws_vpc_ipam_pool_cidr_allocation.vpc_ipam_pool_public
  ]

}

run "negative_invalid_account_cidr" {
  command = plan

  variables {
    acct_ipam_pool_cidr = "10.0..0/40"
  }

  expect_failures = [
    var.acct_ipam_pool_cidr
  ]

}