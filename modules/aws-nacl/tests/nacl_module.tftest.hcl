mock_provider "aws" {}

variables {
  project_name                  = "projecta"
  environment                   = "test"
  vpc_name                      = "infra1"
  vpc_id                        = "vpc-afwpeoijwegt"
  public_subnet_ids             = ["sub1", "sub2"]
  private_subnet_ids            = ["sub3", "sub4"]
  additional_private_subnet_ids = {}
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
  additional_private_subnet_nacl_rules = []
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

run "positive_additional_private_nacl" {
  command = plan

  variables {
    additional_private_subnet_ids = {
      "db" = ["sub5", "sub6"]
    }
  }

  assert {
    condition     = length(aws_network_acl.additional_private_subnet_nacl) == 1
    error_message = "Expected 2 Network ACLS"
  }

}

run "positive_additional_private_nacl_rules" {
  command = plan

  variables {
    additional_private_subnet_ids = {
      "db" = ["sub5", "sub6"]
    }
    additional_private_subnet_nacl_rules = [
      {
        rule_number = 10
        egress      = false
        action      = "allow"
        protocol    = 6
        cidr_block  = "10.0.0.0/8"
        from_port   = 80
        to_port     = 80
        subnet      = "db"
      },
      {
        rule_number = 10
        egress      = true
        action      = "allow"
        protocol    = -1
        cidr_block  = "0.0.0.0/0"
        from_port   = 0
        to_port     = 0
        subnet      = "db"
      },
    ]
    additional_private_subnet_associations = [
      {
        subnet_id    = "sub5"
        subnet_group = "db"
      },
      {
        subnet_id    = "sub6"
        subnet_group = "db"
      }
    ]
  }


  assert {
    condition     = length(aws_network_acl_rule.additional_private_subnet_nacl_rules) == 2
    error_message = "Expected 2 Network ACL Rules"
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

run "negative_invalid_additional_private_rule_cidr" {
  command = plan

  variables {
    additional_private_subnet_ids = {
      "db" = ["sub5", "sub6"]
    }
    additional_private_subnet_nacl_rules = [
      {
        rule_number = 10
        egress      = false
        action      = "allow"
        protocol    = 6
        cidr_block  = "infra1"
        from_port   = 80
        to_port     = 80
        subnet      = "db"
      },
      {
        rule_number = 10
        egress      = true
        action      = "allow"
        protocol    = -1
        cidr_block  = "0.0.0.0/0"
        from_port   = 0
        to_port     = 0
        subnet      = "db"
      },
    ]
    additional_private_subnet_associations = [
      {
        subnet_id    = "sub5"
        subnet_group = "db"
      },
      {
        subnet_id    = "sub6"
        subnet_group = "db"
      }
    ]
  }

  expect_failures = [
    aws_network_acl_rule.additional_private_subnet_nacl_rules
  ]

}