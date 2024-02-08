# ------------------------------------------------------------------------------
# AWS IPAM MODULE
#
# 1. Create IPAM Scope for Account
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

#Create IPAM Scope for Account
resource "aws_vpc_ipam" "account_ipam" {
  description = "${var.project_name}-${var.environment}-account-ipan"
  operating_regions {
    region_name = data.aws_region.current.name
  }
  tags = {
    key   = "Name",
    value = "${var.project_name}-${var.environment}-account-ipam"
  }
}

resource "aws_vpc_ipam_pool" "acct_ipam_pool" {
  description                       = "${var.project_name}-${var.environment}-vpc-ipam-pool"
  address_family                    = "ipv4"
  allocation_default_netmask_length = 16
  ipam_scope_id                     = aws_vpc_ipam.account_ipam.private_default_scope_id
}

resource "aws_vpc_ipam_pool_cidr" "acct_ipam_pool_cidr" {
  ipam_pool_id = aws_vpc_ipam_pool.acct_ipam_pool.id
  cidr         = var.parent_pool_cidr_block
}