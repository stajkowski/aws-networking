output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.vpc_network.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR Block"
  value       = aws_vpc.vpc_network.cidr_block
}

output "vpc_default_sg_id" {
  description = "VPC Default Security Group ID"
  value       = aws_security_group.vpc_default_sg.id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = aws_subnet.public_subnet[*].id
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = aws_subnet.private_subnet[*].id
}

output "additional_private_subnet_ids" {
  description = "Additional Private Subnet IDs"
  value = {
    for subnet_group in flatten(distinct([for l in var.additional_private_subnets : split("::", l)[0]])) : subnet_group => flatten([
      for subnet in var.additional_private_subnets : [
        split("::", subnet_group)[0] == split("::", subnet)[0] ? aws_subnet.additional_private_subnet[subnet].id : null
      ]
    ])
  }
}

output "public_availability_zones" {
  description = "Public Availability Zones"
  value       = aws_subnet.public_subnet[*].availability_zone
}

output "private_availability_zones" {
  description = "Private Availability Zones"
  value       = aws_subnet.private_subnet[*].availability_zone
}

output "public_route_table_id" {
  description = "Public Route Table ID"
  value       = aws_route_table.public_route_table.id
}

output "private_route_table_ids" {
  description = "Private Route Table IDs"
  value       = [for rt in aws_route_table.private_route_table : rt.id]
}

output "bastion_subnet_id" {
  description = "Bastion Subnet ID"
  value       = length(aws_subnet.public_subnet) > 0 ? aws_subnet.public_subnet[0].id : ""
}