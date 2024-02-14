output "acct_ipam_scope_id" {
  description = "Account IPAM Scope ID"
  value       = local.private_default_scope_id[0]
}

output "acct_ipam_pool_id" {
  description = "Account IPAM Pool ID"
  value       = aws_vpc_ipam_pool.region_ipam_pool.id
}