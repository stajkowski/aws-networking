mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
}

variables {
  project_name           = "projecta"
  environment            = "test"
  parent_pool_cidr_block = "10.0.0.0/8"
  ipam_scope_id          = null
}

run "positive_standard_config" {
  command = plan

  assert {
    condition     = length(aws_vpc_ipam.region_ipam) == 1
    error_message = "Expected 1 IPAM Account ID Created"
  }

}

run "positive_ipam_scope_id_exists" {
  command = plan

  variables {
    ipam_scope_id = "ipam-scope-04dd36eca6021f93e"
  }

  assert {
    condition     = length(aws_vpc_ipam.region_ipam) == 0
    error_message = "Expected 1 IPAM Account ID Created"
  }

}