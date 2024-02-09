# ------------------------------------------------------------------------------
# VPC TRANSIT GATEWAY VPC
# 1. Create Transit Gateway
# 2. Create Transit Gateway Attachment
# 3. Update VPC Route Tables
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

# Create Transit Gateway
resource "aws_ec2_transit_gateway" "transit_gateway" {
  description = "${var.project_name}-${var.environment}-tgw"
  tags = {
    Name = "${var.project_name}-${var.environment}-tgw"
  }
  lifecycle {
    precondition {
      condition     = length(var.route_table_routes) > 0
      error_message = "No route_destinations specified in vpcs.[vpc_name].tgw_config.route_destinations. This will break connectivity."
    }
  }
}

# Create Transit Gateway Attachment
# NOTE: If for some reason there are no private subnets, configure
#       the attachment to use the public subnets instead.
resource "aws_ec2_transit_gateway_vpc_attachment" "transit_gateway" {
  for_each           = toset(var.tgw_vpc_attach)
  subnet_ids         = length(var.vpcs[each.key].private_subnet_ids) == 0 ? var.vpcs[each.key].public_subnet_ids : var.vpcs[each.key].private_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  vpc_id             = var.vpcs[each.key].vpc_id
  tags = {
    Name = "${var.project_name}-${var.environment}-${each.key}-tgw"
  }
  lifecycle {
    precondition {
      condition     = can(var.vpcs[each.key].private_subnet_ids)
      error_message = "Invalid VPC reference in transit_gw.tgw_vpc_attach for Transit Gateway Attachment."
    }
  }
}

# Update VPC Route Tables
resource "aws_route" "tgw_route" {
  count                  = length(var.route_table_routes)
  route_table_id         = var.route_table_routes[count.index].route_table_id
  destination_cidr_block = var.route_table_routes[count.index].destination
  transit_gateway_id     = aws_ec2_transit_gateway.transit_gateway.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.transit_gateway]
}