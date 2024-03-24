output "acct_ipam_scope_id" {
  description = "Account IPAM Scope ID"
  value       = var.ipam_scope_id != null ? var.ipam_scope_id : aws_vpc_ipam.region_ipam[0].private_default_scope_id
}

output "acct_ipam_pool_id" {
  description = "Account IPAM Pool ID"
  value       = aws_vpc_ipam_pool.region_ipam_pool.id
}