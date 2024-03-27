# ---------------------------------------------------------------------------------------------------------------------
# AWS NETWORKING MODULE
#
# Purpose: This module is used to create various AWS networking services within a VPC or a set of VPCs.  The module
# attempts to provide some flexibility in confirguration by allowing dynamic creation of public/private subnets. 
# VPC can be created with or without public subnets, NAT GW, IGW or Transit GW attachment.  Please note that if a
# public NAT GW is created, there must be a public subnet to attach it to.
#
# 1. Create VPC, Public/Private Subnets, Route Tables, and Default Security Group
# 2. Create NACLs for VPCs
# 3. Create Internet Gateway, NAT Gateway, VPCE Gateway, or VPC Interface Endpoints
# 4. Create Transit Gateway, Attach VPCs, and update VPC Route Tables
# 5. Create Internet Monitor
# 6. Create Client VPN
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

# Create Account IPAM Pool
module "aws-acct-ipam" {
  source                 = "./modules/aws-acct-ipam"
  project_name           = var.project_name
  environment            = var.environment
  parent_pool_cidr_block = var.parent_pool_cidr_block
  ipam_scope_id          = var.ipam_scope_id
}

# Create VPC with Public and Private Subnets
module "aws-vpc" {
  source                  = "./modules/aws-vpc"
  depends_on              = [module.aws-acct-ipam]
  for_each                = var.network_config.vpcs
  project_name            = var.project_name
  environment             = var.environment
  vpc_name                = each.key
  acct_ipam_scope_id      = module.aws-acct-ipam.acct_ipam_scope_id
  acct_ipam_pool_id       = module.aws-acct-ipam.acct_ipam_pool_id
  acct_ipam_pool_cidr     = var.parent_pool_cidr_block
  public_subnets          = each.value.public_subnets
  private_subnets         = each.value.private_subnets
  route_table_per_private = each.value.gw_services.nat_gw_ha
  vpc_cidr_subnet_mask    = each.value.vpc_cidr_subnet_mask
  subnet_mask             = each.value.subnet_mask
  # Additional private subnets will encode a format that informs the:
  # 1. Subnet Group
  # 2. Subnet Index
  # 3. Subnet Count for Group
  additional_private_subnets = flatten([
    for k, v in each.value.additional_private_subnets : [
      for i in range(v.subnet_count) : [
        "${k}::${i + 1}::${i}"
      ]
    ]
  ])
}

# Create NACLs for VPCs
module "aws-nacl" {
  source                        = "./modules/aws-nacl"
  depends_on                    = [module.aws-vpc]
  for_each                      = var.network_config.vpcs
  project_name                  = var.project_name
  environment                   = var.environment
  vpc_name                      = each.key
  vpc_id                        = module.aws-vpc[each.key].vpc_id
  public_subnet_ids             = module.aws-vpc[each.key].public_subnet_ids
  private_subnet_ids            = module.aws-vpc[each.key].private_subnet_ids
  additional_private_subnet_ids = module.aws-vpc[each.key].additional_private_subnet_ids
  additional_private_subnet_associations = flatten([
    for k, v in module.aws-vpc[each.key].additional_private_subnet_ids : [
      for sn in v : {
        subnet_id    = sn
        subnet_group = k
      }
    ]
  ])
  public_subnet_nacl_rules = [for rule in each.value.public_subnet_nacl_rules : {
    rule_number = rule.rule_number
    egress      = rule.egress
    protocol    = rule.protocol
    action      = rule.action
    cidr_block  = can(lookup(var.network_config.vpcs, rule.cidr_block)) ? module.aws-vpc[rule.cidr_block].vpc_cidr_block : replace(rule.cidr_block, "ipam_account_pool", var.parent_pool_cidr_block)
    from_port   = rule.from_port
    to_port     = rule.to_port
  }]
  private_subnet_nacl_rules = [
    for rule in each.value.private_subnet_nacl_rules : {
      rule_number = rule.rule_number
      egress      = rule.egress
      protocol    = rule.protocol
      action      = rule.action
      cidr_block  = can(lookup(var.network_config.vpcs, rule.cidr_block)) ? module.aws-vpc[rule.cidr_block].vpc_cidr_block : replace(rule.cidr_block, "ipam_account_pool", var.parent_pool_cidr_block)
      from_port   = rule.from_port
      to_port     = rule.to_port
    }
  ]
  additional_private_subnet_nacl_rules = flatten([
    for k, v in each.value.additional_private_subnets : [
      for rule in v.nacl_rules : {
        rule_number = rule.rule_number
        egress      = rule.egress
        protocol    = rule.protocol
        action      = rule.action
        cidr_block  = can(lookup(var.network_config.vpcs, rule.cidr_block)) ? module.aws-vpc[rule.cidr_block].vpc_cidr_block : replace(rule.cidr_block, "ipam_account_pool", var.parent_pool_cidr_block)
        from_port   = rule.from_port
        to_port     = rule.to_port
        subnet      = k
      }
    ]
  ])
}

# Setup IGW and NAT Gateway
module "aws-vpc-gw" {
  source             = "./modules/aws-vpc-gw"
  depends_on         = [module.aws-vpc]
  for_each           = var.network_config.vpcs
  project_name       = var.project_name
  environment        = var.environment
  vpc_name           = each.key
  vpc_id             = module.aws-vpc[each.key].vpc_id
  public_subnet_ids  = module.aws-vpc[each.key].public_subnet_ids
  private_subnet_ids = module.aws-vpc[each.key].private_subnet_ids
  additional_private_subnet_ids = flatten([
    for k, v in module.aws-vpc[each.key].additional_private_subnet_ids : [
      for sn in v : sn
    ]
  ])
  public_route_table_id           = module.aws-vpc[each.key].public_route_table_id
  private_route_table_ids         = module.aws-vpc[each.key].private_route_table_ids
  igw_is_enabled                  = each.value.gw_services.igw_is_enabled
  nat_gw_is_enabled               = each.value.gw_services.nat_gw_is_enabled
  nat_gw_type                     = each.value.gw_services.nat_gw_type
  vpc_gateway_services            = each.value.gw_services.vpc_gateway_services
  vpc_interface_services          = each.value.gw_services.vpc_interface_services
  vpc_interface_services_scope    = each.value.gw_services.vpc_interface_services_scope
  vpc_interface_security_group_id = module.aws-vpc[each.key].vpc_default_sg_id
}

# Setup Transit Gateway
module "aws-vpc-tgw" {
  source       = "./modules/aws-vpc-tgw"
  depends_on   = [module.aws-vpc-gw]
  count        = var.network_config.transit_gw.tgw_is_enabled ? 1 : 0
  project_name = var.project_name
  environment  = var.environment
  vpcs = {
    for vpc in var.network_config.transit_gw.tgw_vpc_attach : vpc => {
      vpc_id             = module.aws-vpc[vpc].vpc_id
      public_subnet_ids  = module.aws-vpc[vpc].public_subnet_ids
      private_subnet_ids = module.aws-vpc[vpc].private_subnet_ids
      additional_private_subnet_ids = flatten([
        for k, v in module.aws-vpc[vpc].additional_private_subnet_ids : [
          for sn in v : sn
        ]
      ])
    }
  }
  # Setup route table routes for a many to many relationship due to HA
  # configuration on private subnets for NAT GWs.  For each route table,
  # create a route for each destination in the destination list for the
  # vpc. Output is a list for each route table and destination.
  route_table_routes = flatten([
    for vpc in var.network_config.transit_gw.tgw_vpc_attach : [
      for route_table_id in concat(module.aws-vpc[vpc].private_route_table_ids, [module.aws-vpc[vpc].public_route_table_id]) : [
        for destination in var.network_config.vpcs[vpc].tgw_config.route_destinations : {
          route_table_id = route_table_id
          destination    = can(module.aws-vpc[destination].vpc_cidr_block) ? module.aws-vpc[destination].vpc_cidr_block : destination
        }
      ]
    ]
  ])
  tgw_routes = flatten([
    for route in var.network_config.transit_gw.tgw_routes : {
      destination    = can(module.aws-vpc[route.destination].vpc_cidr_block) ? module.aws-vpc[route.destination].vpc_cidr_block : route.destination
      vpc_attachment = route.vpc_attachment
    }
  ])
  tgw_vpc_attach = var.network_config.transit_gw.tgw_vpc_attach
}

# Create Internet Monitor
module "aws-cw-internet-monitor" {
  source                  = "./modules/aws-cw-internet-monitor"
  depends_on              = [module.aws-vpc]
  project_name            = var.project_name
  environment             = var.environment
  internet_monitor_config = var.network_config.internet_monitor
  aws_vpc                 = module.aws-vpc
}




# Create Client VPN Certs in ACM
resource "aws_acm_certificate" "server_vpn_cert" {
  count             = var.network_config.vpn.client_vpn.is_enabled && fileexists("${path.module}/config/vpn/server.crt") ? 1 : 0
  certificate_body  = file("${path.module}/config/vpn/server.crt")
  private_key       = file("${path.module}/config/vpn/server.key")
  certificate_chain = file("${path.module}/config/vpn/ca.crt")
}

resource "aws_acm_certificate" "client_vpn_cert" {
  count             = var.network_config.vpn.client_vpn.is_enabled && fileexists("${path.module}/config/vpn/client.crt") ? 1 : 0
  certificate_body  = file("${path.module}/config/vpn/client.crt")
  private_key       = file("${path.module}/config/vpn/client.key")
  certificate_chain = file("${path.module}/config/vpn/ca.crt")
}

resource "aws_security_group" "vpn_security_group" {
  count             = var.network_config.vpn.client_vpn.is_enabled ? 1 : 0
  name   = "${var.project_name}-${var.environment}-vpn-sg"
  vpc_id = module.aws-vpc[var.network_config.vpn.client_vpn.vpc_connection].vpc_id
  description = "Allow inbound traffic from port 443, to the VPN"
 
  ingress {
   protocol         = "tcp"
   from_port        = 443
   to_port          = 443
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }
 
  egress {
   protocol         = "-1"
   from_port        = 0
   to_port          = 0
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_ec2_client_vpn_endpoint" "client_vpn" {
  count             = var.network_config.vpn.client_vpn.is_enabled ? 1 : 0
  description            = "${var.project_name}-${var.environment}-client-vpn"
  server_certificate_arn = aws_acm_certificate.server_vpn_cert[0].arn
  client_cidr_block      = var.network_config.vpn.client_vpn.client_cidr_block
  vpc_id                 = module.aws-vpc[var.network_config.vpn.client_vpn.vpc_connection].vpc_id
  
  transport_protocol = var.network_config.vpn.client_vpn.vpn_protocol
  vpn_port = var.network_config.vpn.client_vpn.vpn_port

  security_group_ids     = [aws_security_group.vpn_security_group[0].id]
  split_tunnel           = true

  # Client authentication
  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.client_vpn_cert[0].arn
  }

  connection_log_options {
    enabled = false
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-client-vpn"
  }

  depends_on = [
    aws_acm_certificate.server_vpn_cert,
    aws_acm_certificate.client_vpn_cert
  ]

  lifecycle {
    precondition {
      condition     = length(aws_acm_certificate.server_vpn_cert) > 0 && length(aws_acm_certificate.client_vpn_cert) > 0
      error_message = "Please execute terraform-aws-networking/bin/run_generate_vpn_certs.sh prior to enabling the Client VPN for the first time."
    }
  }
}

resource "aws_ec2_client_vpn_network_association" "client_vpn_association_private" {
  count                  = length(aws_ec2_client_vpn_endpoint.client_vpn) > 0 ? length(module.aws-vpc[var.network_config.vpn.client_vpn.vpc_connection].private_subnet_ids) : 0
  depends_on = [ aws_ec2_client_vpn_endpoint.client_vpn ]
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.client_vpn[0].id
  subnet_id              = module.aws-vpc[var.network_config.vpn.client_vpn.vpc_connection].private_subnet_ids[count.index]
}

resource "aws_ec2_client_vpn_authorization_rule" "authorization_rule" {
  count             = length(aws_ec2_client_vpn_endpoint.client_vpn) > 0 ? 1 : 0
  depends_on = [ aws_ec2_client_vpn_endpoint.client_vpn ]
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.client_vpn[0].id
  
  target_network_cidr    = can(lookup(var.network_config.vpcs, var.network_config.vpn.client_vpn.target_network)) ? module.aws-vpc[var.network_config.vpn.client_vpn.target_network].vpc_cidr_block : replace(var.network_config.vpn.client_vpn.target_network, "ipam_account_pool", var.parent_pool_cidr_block)
  authorize_all_groups   = true
}

resource "local_sensitive_file" "client_ovpn_config" {
  count = length(aws_ec2_client_vpn_endpoint.client_vpn) > 0  ? 1 : 0
  depends_on = [ aws_ec2_client_vpn_endpoint.client_vpn ]
  filename = var.network_config.vpn.client_vpn.ovpn_export_path
  content = <<-EOT
client
dev tun
proto ${var.network_config.vpn.client_vpn.vpn_protocol}
remote ${replace(aws_ec2_client_vpn_endpoint.client_vpn[0].dns_name,"*.","")} ${var.network_config.vpn.client_vpn.vpn_port}
remote-random-hostname
resolv-retry infinite
nobind
remote-cert-tls server
cipher AES-256-GCM
verb 3
<ca>
${file("${path.module}/config/vpn/ca.crt")}
</ca>
<cert>
${file("${path.module}/config/vpn/client.crt")}
</cert>
<key>
${file("${path.module}/config/vpn/client.key")}
</key>
reneg-sec 0
verify-x509-name server.vpn.local name
EOT
}