mock_provider "aws" {}

variables {
  project_name       = "projecta"
  environment        = "test"
  vpc_name           = "infra1"
  vpc_id             = "vpc-afwpeoijwegt"
  public_subnet_ids  = ["sub1", "sub2"]
  private_subnet_ids = ["sub3", "sub4"]
  public_subnet_nacl_rules = [
    {
      rule_number = 10
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
    },
  ]
  private_subnet_nacl_rules = [
    {
      rule_number = 10
      egress      = false
      action      = "allow"
      protocol    = 6
      cidr_block  = "10.0.0.0/8"
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
    },
  ]
}

run "positive_standard_config" {
  command = plan

  assert {
    condition     = length(aws_network_acl.public_subnet_nacl) == 1 && length(aws_network_acl.private_subnet_nacl) == 1
    error_message = "Expected 2 Network ACLS"
  }

}

run "positive_standard_config_nacl_rule_creation" {
  command = plan

  assert {
    condition     = length(aws_network_acl_rule.public_subnet_nacl_rules) == 2 && length(aws_network_acl_rule.private_subnet_nacl_rules) == 2
    error_message = "Expected 2 Network ACLS"
  }

}

run "positive_standard_config_nacl_rule_association" {
  command = plan

  assert {
    condition     = length(aws_network_acl_association.public_subnet_nacl_association) == 2 && length(aws_network_acl_association.private_subnet_nacl_association) == 2
    error_message = "Expected 2 Network ACLS"
  }

}

run "positive_no_public_subnets" {
  command = plan

  variables {
    public_subnet_ids = []
  }

  assert {
    condition     = length(aws_network_acl_rule.public_subnet_nacl_rules) == 0
    error_message = "Expected 0 Public NACL Rules"
  }

}

run "positive_no_private_subnets" {
  command = plan

  variables {
    private_subnet_ids = []
  }

  assert {
    condition     = length(aws_network_acl_rule.private_subnet_nacl_rules) == 0
    error_message = "Expected 0 Private NACL Rules"
  }

}

run "negative_invalid_public_rule_cidr" {
  command = plan

  variables {
    public_subnet_nacl_rules = [
      {
        rule_number = 10
        egress      = false
        action      = "allow"
        protocol    = 6
        cidr_block  = "infra"
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
      },
    ]
  }

  expect_failures = [
    aws_network_acl_rule.public_subnet_nacl_rules
  ]

}

run "negative_invalid_private_rule_cidr" {
  command = plan

  variables {
    private_subnet_nacl_rules = [
      {
        rule_number = 10
        egress      = false
        action      = "allow"
        protocol    = 6
        cidr_block  = "infra"
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
      },
    ]
  }

  expect_failures = [
    aws_network_acl_rule.private_subnet_nacl_rules
  ]

}