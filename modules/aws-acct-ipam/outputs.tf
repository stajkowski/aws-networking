output "acct_ipam_scope_id" {
  description = "Account IPAM Scope ID"
  value       = aws_vpc_ipam.account_ipam.private_default_scope_id
}

output "acct_ipam_pool_id" {
  description = "Account IPAM Pool ID"
  value       = aws_vpc_ipam_pool.acct_ipam_pool.id
}