# ---------------------------------------------------------------------------------------------------------------------
# VPC/SUBNET/ROUTE TABLE MODULE ON AWS
# 
# 1. Create IPAM VPC Pool and Allocate Subnets
# 1. Create VPC with Input CIDR Block
# 2. Create IPAM Pool and Allocate Subnets
# 3. Create Public and Private Subnets
# 4. Associate with Route Table
# 5. Create Internet Gateway and NAT Gateway
# 6. Create Default Security Group
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

data "aws_availability_zones" "available" {
  state = "available"
}

# TODO Implement non-routeable CIDR blocks for the private subnets
#      to prevent IP exhaustion
# Create Pool for this VPC
resource "aws_vpc_ipam_pool" "vpc_subnet_ipam_pool" {
  description                       = "${var.project_name}-${var.environment}-vpc-${var.vpc_name}-subnet-ipam-pool"
  address_family                    = "ipv4"
  allocation_default_netmask_length = var.subnet_mask
  ipam_scope_id                     = var.acct_ipam_scope_id
  source_ipam_pool_id               = var.acct_ipam_pool_id
}

resource "aws_vpc_ipam_pool_cidr" "vpc_subnet_ipam_pool_cidr" {
  ipam_pool_id   = aws_vpc_ipam_pool.vpc_subnet_ipam_pool.id
  netmask_length = var.vpc_cidr_subnet_mask
  lifecycle {
    precondition {
      condition     = var.vpc_cidr_subnet_mask > split("/", var.acct_ipam_pool_cidr)[1]
      error_message = "VPC CIDR subnet mask must be greater than the account IPAM pool CIDR subnet mask."
    }
  }
}

# Allocate IPAM public and private subnets
resource "aws_vpc_ipam_pool_cidr_allocation" "vpc_ipam_pool_public" {
  count          = var.public_subnets
  ipam_pool_id   = aws_vpc_ipam_pool.vpc_subnet_ipam_pool.id
  description    = "${var.project_name}-${var.environment}-vpc-${var.vpc_name}-public-subnet-${count.index + 1}"
  netmask_length = var.subnet_mask

  depends_on = [
    aws_vpc_ipam_pool.vpc_subnet_ipam_pool,
    aws_vpc_ipam_pool_cidr.vpc_subnet_ipam_pool_cidr
  ]

  lifecycle {
    precondition {
      condition     = var.subnet_mask > var.vpc_cidr_subnet_mask
      error_message = "Subnet mask must be greater than VPC CIDR subnet mask."
    }
  }
}

resource "aws_vpc_ipam_pool_cidr_allocation" "vpc_ipam_pool_private" {
  count          = var.private_subnets
  ipam_pool_id   = aws_vpc_ipam_pool.vpc_subnet_ipam_pool.id
  description    = "${var.project_name}-${var.environment}-vpc-${var.vpc_name}-private-subnet-${count.index + 1}"
  netmask_length = var.subnet_mask

  depends_on = [
    aws_vpc_ipam_pool.vpc_subnet_ipam_pool,
    aws_vpc_ipam_pool_cidr.vpc_subnet_ipam_pool_cidr,
    aws_vpc_ipam_pool_cidr_allocation.vpc_ipam_pool_public
  ]

  lifecycle {
    precondition {
      condition     = var.subnet_mask > var.vpc_cidr_subnet_mask
      error_message = "Subnet mask must be greater than VPC CIDR subnet mask."
    }
  }
}

resource "aws_vpc_ipam_pool_cidr_allocation" "vpc_ipam_pool_additional_private" {
  for_each       = toset(var.additional_private_subnets)
  ipam_pool_id   = aws_vpc_ipam_pool.vpc_subnet_ipam_pool.id
  description    = "${var.project_name}-${var.environment}-vpc-${var.vpc_name}-private-subnet-${split("::", each.value)[0]}"
  netmask_length = var.subnet_mask

  depends_on = [
    aws_vpc_ipam_pool.vpc_subnet_ipam_pool,
    aws_vpc_ipam_pool_cidr.vpc_subnet_ipam_pool_cidr,
    aws_vpc_ipam_pool_cidr_allocation.vpc_ipam_pool_public,
    aws_vpc_ipam_pool_cidr_allocation.vpc_ipam_pool_private
  ]

  lifecycle {
    precondition {
      condition     = var.subnet_mask > var.vpc_cidr_subnet_mask
      error_message = "Subnet mask must be greater than VPC CIDR subnet mask."
    }
  }
}

# Create VPC with input CIDR block
resource "aws_vpc" "vpc_network" {
  cidr_block           = aws_vpc_ipam_pool_cidr.vpc_subnet_ipam_pool_cidr.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-${var.vpc_name}"
  }
}

# Create public/private subnets based on availability zone count
resource "aws_subnet" "public_subnet" {
  count                   = var.public_subnets
  vpc_id                  = aws_vpc.vpc_network.id
  cidr_block              = aws_vpc_ipam_pool_cidr_allocation.vpc_ipam_pool_public[count.index].cidr
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-${var.environment}-${var.vpc_name}-public-subnet-${count.index + 1}"
  }
  depends_on = [aws_vpc_ipam_pool_cidr_allocation.vpc_ipam_pool_public]
}

resource "aws_subnet" "private_subnet" {
  count             = var.private_subnets
  vpc_id            = aws_vpc.vpc_network.id
  cidr_block        = aws_vpc_ipam_pool_cidr_allocation.vpc_ipam_pool_private[count.index].cidr
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.project_name}-${var.environment}-${var.vpc_name}-private-subnet-${count.index + 1}"
  }
  depends_on = [aws_vpc_ipam_pool_cidr_allocation.vpc_ipam_pool_private]
}

resource "aws_subnet" "additional_private_subnet" {
  for_each          = toset(var.additional_private_subnets)
  vpc_id            = aws_vpc.vpc_network.id
  cidr_block        = aws_vpc_ipam_pool_cidr_allocation.vpc_ipam_pool_additional_private[each.value].cidr
  availability_zone = data.aws_availability_zones.available.names[split("::", each.value)[1]]
  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-${var.vpc_name}-private-subnet-${split("::", each.value)[0]}"
  }
  depends_on = [aws_vpc_ipam_pool_cidr_allocation.vpc_ipam_pool_additional_private]
}

# Create the public/private route tables
# TODO Check for count of public subnets and if 0 don't create RT
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc_network.id
  tags = {
    Name = "${var.project_name}-${var.environment}-${var.vpc_name}-public-route-table."
  }
}

resource "aws_route_table" "private_route_table" {
  count  = var.route_table_per_private ? var.private_subnets : 1
  vpc_id = aws_vpc.vpc_network.id
  tags = {
    Name = "${var.project_name}-${var.environment}-${var.vpc_name}-private-route-table-${count.index + 1}"
  }
}

# Associate public and private subnets with the route table
resource "aws_route_table_association" "public_subnet_association" {
  count          = var.public_subnets
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_association" {
  count          = var.private_subnets
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = var.route_table_per_private ? aws_route_table.private_route_table[count.index].id : aws_route_table.private_route_table[0].id
}

resource "aws_route_table_association" "additional_private_subnet_association" {
  for_each       = toset(var.additional_private_subnets)
  subnet_id      = aws_subnet.additional_private_subnet[each.value].id
  route_table_id = var.route_table_per_private ? aws_route_table.private_route_table[split("::", each.value)[1]].id : aws_route_table.private_route_table[0].id
}

# Create Default VPC Security Group
# TODO Update to grab passed ipam parent pool cidr
resource "aws_security_group" "vpc_default_sg" {
  name        = "${var.project_name}-${var.environment}-default-sg"
  description = "Default security group to allow inbound/outbound from the account IPAM pool."
  vpc_id      = aws_vpc.vpc_network.id
  depends_on  = [aws_vpc.vpc_network]
  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = [var.acct_ipam_pool_cidr]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.project_name}-${var.environment}-${var.vpc_name}-default-sg"
  }
}