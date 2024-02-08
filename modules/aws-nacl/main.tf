# ---------------------------------------------------------------------------------------------------------------------
# NACL MODULE ON AWS
# 
# 1. Create NACLs for public and private subnets
# 2. Create NACL rules for public and private subnets
# 2. Associate NACL with public and private subnets
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

# Create NACLs for public and private subnets
resource "aws_network_acl" "public_subnet_nacl" {
  count  = length(var.public_subnet_ids) > 0 ? 1 : 0
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.project_name}-${var.environment}-${var.vpc_name}-public-subnet-nacl"
  }
}

resource "aws_network_acl" "private_subnet_nacl" {
  count  = length(var.private_subnet_ids) > 0 ? 1 : 0
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.project_name}-${var.environment}-${var.vpc_name}-private-subnet-nacl"
  }
}

resource "aws_network_acl_rule" "public_subnet_nacl_rules" {
  count          = length(var.public_subnet_ids) > 0 ? length(var.public_subnet_nacl_rules) : 0
  network_acl_id = length(aws_network_acl.public_subnet_nacl) > 0 ? aws_network_acl.public_subnet_nacl[0].id : ""
  rule_number    = var.public_subnet_nacl_rules[count.index].rule_number
  egress         = var.public_subnet_nacl_rules[count.index].egress
  protocol       = var.public_subnet_nacl_rules[count.index].protocol
  rule_action    = var.public_subnet_nacl_rules[count.index].action
  cidr_block     = var.public_subnet_nacl_rules[count.index].cidr_block
  from_port      = var.public_subnet_nacl_rules[count.index].from_port
  to_port        = var.public_subnet_nacl_rules[count.index].to_port
  depends_on     = [aws_network_acl.public_subnet_nacl]
  lifecycle {
    precondition {
      condition     = can(cidrsubnet(var.public_subnet_nacl_rules[count.index].cidr_block, 0, 0))
      error_message = "Invalid NACL rule cidr_block. Ensure shorthand names are referenced correctly in rules to valid VPC names or ipam_account_pool."
    }
  }
}

resource "aws_network_acl_rule" "private_subnet_nacl_rules" {
  count          = length(var.private_subnet_ids) > 0 ? length(var.private_subnet_nacl_rules) : 0
  network_acl_id = length(aws_network_acl.private_subnet_nacl) > 0 ? aws_network_acl.private_subnet_nacl[0].id : ""
  rule_number    = var.private_subnet_nacl_rules[count.index].rule_number
  egress         = var.private_subnet_nacl_rules[count.index].egress
  protocol       = var.private_subnet_nacl_rules[count.index].protocol
  rule_action    = var.private_subnet_nacl_rules[count.index].action
  cidr_block     = var.private_subnet_nacl_rules[count.index].cidr_block
  from_port      = var.private_subnet_nacl_rules[count.index].from_port
  to_port        = var.private_subnet_nacl_rules[count.index].to_port
  depends_on     = [aws_network_acl.private_subnet_nacl]
  lifecycle {
    precondition {
      condition     = can(cidrsubnet(var.private_subnet_nacl_rules[count.index].cidr_block, 0, 0))
      error_message = "Invalid NACL rule CIDR block. Ensure shorthand names are referenced correctly in rules to valid VPC names or ipam_account_pool."
    }
  }
}

# Associate NACL with public and private subnets
resource "aws_network_acl_association" "public_subnet_nacl_association" {
  count          = length(var.public_subnet_ids)
  subnet_id      = var.public_subnet_ids[count.index]
  network_acl_id = length(aws_network_acl.public_subnet_nacl) > 0 ? aws_network_acl.public_subnet_nacl[0].id : ""
  depends_on     = [aws_network_acl.public_subnet_nacl]
}

resource "aws_network_acl_association" "private_subnet_nacl_association" {
  count          = length(var.private_subnet_ids)
  subnet_id      = var.private_subnet_ids[count.index]
  network_acl_id = length(aws_network_acl.private_subnet_nacl) > 0 ? aws_network_acl.private_subnet_nacl[0].id : ""
  depends_on     = [aws_network_acl.private_subnet_nacl]
}