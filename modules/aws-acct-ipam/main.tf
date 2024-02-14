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
data "aws_vpc_ipam_pools" "region_ipam_pools" {
  filter {
    name   = "address-family"
    values = ["ipv4"]
  }
}

#Create IPAM Scope for Account
resource "aws_vpc_ipam" "region_ipam" {
  count       = length(data.aws_vpc_ipam_pools.region_ipam_pools.ipam_pools) == 0 ? 1 : 0
  description = "${var.project_name}-${var.environment}-account-ipan"
  operating_regions {
    region_name = data.aws_region.current.name
  }
  tags = {
    key   = "Name",
    value = "${var.project_name}-${var.environment}-account-ipam"
  }
}

#If no IPAM pools exist, then use the created scope, otherwise use the first pool
locals {
  depends_on               = [data.aws_vpc_ipam_pools.region_ipam_pools, aws_vpc_ipam.region_ipam]
  private_default_scope_id = length(data.aws_vpc_ipam_pools.region_ipam_pools.ipam_pools) == 0 ? aws_vpc_ipam.region_ipam[*].private_default_scope_id : data.aws_vpc_ipam_pools.region_ipam_pools.ipam_pools[*].ipam_scope_id
}

#TODO Check for pool overlap for the main parent pool if scope already exists and add tests
resource "aws_vpc_ipam_pool" "region_ipam_pool" {
  description                       = "${var.project_name}-${var.environment}-vpc-ipam-pool"
  address_family                    = "ipv4"
  allocation_default_netmask_length = 16
  ipam_scope_id                     = local.private_default_scope_id[0]
}

resource "aws_vpc_ipam_pool_cidr" "acct_ipam_pool_cidr" {
  ipam_pool_id = aws_vpc_ipam_pool.region_ipam_pool.id
  cidr         = var.parent_pool_cidr_block
}