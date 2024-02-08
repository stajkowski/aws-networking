# ---------------------------------------------------------------------------------------------------------------------
# VPC IGW & NAT GATEWAY MODULE ON AWS
#
# 1. Create Internet Gateway
# 2. Attach Internet Gateway to VPC
# 3. Update Public Route Table with Default Route to Internet Gateway
# 3. Create Elastic IP for NAT Gateway
# 5. Create NAT Gateway
# 6. Associate with Private Subnets
# 7. Associate Elastic IP with NAT Gateway
# 9. Update Private Route Table with Default Route to NAT Gateway
# 10. Create VPC Gateway Endpoints for S3 and DynamoDB
# 11. Associate VPC Gateway Endpoints with Route Tables
# 12. Create VPC Interface Endpoints for Services
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

data "aws_region" "current" {}

# Create IGW and Update Public Route Table
resource "aws_internet_gateway" "igw" {
  count  = var.igw_is_enabled ? 1 : 0
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.project_name}-${var.environment}-${var.vpc_name}-igw"
  }
  lifecycle {
    precondition {
      condition     = length(var.public_subnet_ids) > 0
      error_message = "Public Subnets are required to create an Internet Gateway"
    }
  }
}

resource "aws_route" "igw_default_route" {
  count                  = var.igw_is_enabled ? 1 : 0
  route_table_id         = var.public_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[count.index].id
  depends_on             = [aws_internet_gateway.igw]
}

# Create NAT Gateway and Update Private Route Table
#  - Public type in HA config will create an EIP and NAT GW for each Private RT
#  - Private type in HA config will create a NAT GW for each Private RT
#  - Public and Private in non-HA config will create a single NAT GW and associate
#    with all either the first public or private subnet depending on type 
resource "aws_eip" "nat_eip" {
  count = var.nat_gw_type == "public" && var.nat_gw_is_enabled ? length(var.private_route_table_ids) : 0

  lifecycle {
    precondition {
      condition     = length(var.public_subnet_ids) > 0 && var.igw_is_enabled
      error_message = "Public Subnets & IGW are required to create a Public NAT Gateway"
    }
  }
}

resource "aws_nat_gateway" "nat_gw" {
  count             = var.nat_gw_is_enabled ? length(var.private_route_table_ids) : 0
  depends_on        = [aws_internet_gateway.igw]
  connectivity_type = var.nat_gw_type
  allocation_id     = var.nat_gw_type == "public" ? aws_eip.nat_eip[count.index].id : null
  subnet_id         = var.nat_gw_type == "public" ? var.public_subnet_ids[count.index] : var.private_subnet_ids[count.index]
  tags = {
    Name = "${var.project_name}-${var.environment}-${var.vpc_name}-nat-gw-${count.index + 1}"
  }

  lifecycle {
    precondition {
      condition     = length(var.private_subnet_ids) > 0
      error_message = "Private Subnets are required to create a NAT Gateway"
    }
  }
}

resource "aws_route" "nat_gw_default_route" {
  count                  = var.nat_gw_is_enabled ? length(var.private_route_table_ids) : 0
  route_table_id         = var.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw[count.index].id
}

# Create VPC Gateway Endpoints for S3 and DynamoDB
resource "aws_vpc_endpoint" "vpc_gateway_endpoint" {
  for_each        = toset(var.vpc_gateway_services)
  vpc_id          = var.vpc_id
  service_name    = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  route_table_ids = concat(var.private_route_table_ids, [var.public_route_table_id])
  tags = {
    Name = "${var.project_name}-${var.environment}-${var.vpc_name}-${each.key}-endpoint"
  }
}

# Create VPC Interface Endpoints for Services
# - Endpoint scope will determine subnet ids to place the endpoints in
# - Both will place in all subnets where private is just private subnets
# TODO Maybe add interface endpoint policies
resource "aws_vpc_endpoint" "vpc_interface_endpoint" {
  for_each            = toset(var.vpc_interface_services)
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.vpc_interface_services_scope == "private" ? var.private_subnet_ids : concat(var.public_subnet_ids, var.private_subnet_ids)
  security_group_ids  = [var.vpc_interface_security_group_id]
  dns_options {
    private_dns_only_for_inbound_resolver_endpoint = false
  }
  tags = {
    Name = "${var.project_name}-${var.environment}-${var.vpc_name}-${each.key}-interface-endpoint"
  }
}