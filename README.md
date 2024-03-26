# terraform-aws-networking ![GitHub Release](https://img.shields.io/github/v/release/stajkowski/aws-networking) ![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/stajkowski/terraform-aws-networking/development.yml) ![GitHub commit activity](https://img.shields.io/github/commit-activity/m/stajkowski/terraform-aws-networking)

Terraform Module to simplify the creation of complex AWS VPC Networking configurations.  With a layer of abstraction, you can create multiple vpcs and connect them with Transit Gateway through configurations.  Control NACLs, Security Groups and Routing with simple shorthand reference to the VPC and aws-networking module to ensure the correct values are substituted.  VPC CIDR assignments are derived from the account level IPAM pool and auto assigns VPC CIDRs and Subnet CIDRs.

# Contents
- [Usage Example](#usage-example)
- [Module Requirements](#requirements)
- [Module Providers](#providers)
- [Module Resources](#resources)
- [Module Inputs](#inputs)
- [Module Inputs - network_config](#network-configuration-inputs)
- [Major Revision Updates](#major-revision-updates)
- [Required Permissions](#required-permissions)
- [License](#license)

## Usage Example
*More examples can be found in [Examples](https://github.com/stajkowski/terraform-aws-networking/tree/main/examples)
```
locals {
  project_name           = "projecta"
  environment            = "test"
  parent_pool_cidr_block = "10.0.0.0/8"
  ipam_scope_id          = null
  network_config = {
    "test" = {
      vpcs = {
        "egress" = {
          public_subnets             = 2
          private_subnets            = 2
          vpc_cidr_subnet_mask       = 16
          subnet_mask                = 24
          additional_private_subnets = {}
          public_subnet_nacl_rules = [
            {
              rule_number = 10
              egress      = false
              action      = "allow"
              protocol    = 6
              cidr_block  = "0.0.0.0/0"
              from_port   = 443
              to_port     = 443
            },
            {
              rule_number = 20
              egress      = false
              action      = "allow"
              protocol    = 6
              cidr_block  = "0.0.0.0/0"
              from_port   = 80
              to_port     = 80
            },
            {
              rule_number = 10
              egress      = true
              action      = "allow"
              protocol    = -1
              cidr_block  = "0.0.0.0/0"
              from_port   = 0
              to_port     = 0
            }
          ]
          private_subnet_nacl_rules = [
            {
              rule_number = 10
              egress      = false
              action      = "allow"
              protocol    = -1
              cidr_block  = "infra1"
              from_port   = 0
              to_port     = 0
            },
            {
              rule_number = 20
              egress      = false
              action      = "allow"
              protocol    = 6
              cidr_block  = "ipam_account_pool"
              from_port   = 22
              to_port     = 22
            },
            {
              rule_number = 10
              egress      = true
              action      = "allow"
              protocol    = -1
              cidr_block  = "0.0.0.0/0"
              from_port   = 0
              to_port     = 0
            }
          ]
          gw_services = {
            igw_is_enabled       = true
            nat_gw_is_enabled    = true
            nat_gw_type          = "public"
            nat_gw_ha            = true
            vpc_gateway_services = ["s3"]
            vpc_interface_services = [
              "ec2", "sts"
            ]
            vpc_interface_services_scope = "private"
          }
          tgw_config = {
            route_destinations = ["infra1"]
          }
        }
        "infra1" = {
          public_subnets       = 0
          private_subnets      = 2
          vpc_cidr_subnet_mask = 16
          subnet_mask          = 24
          additional_private_subnets = {
            "db" = {
              subnet_count = 2
              nacl_rules = [
                {
                  rule_number = 10
                  egress      = false
                  action      = "allow"
                  protocol    = 6
                  cidr_block  = "infra1"
                  from_port   = 3306
                  to_port     = 3306
                },
                {
                  rule_number = 20
                  egress      = false
                  action      = "allow"
                  protocol    = 6
                  cidr_block  = "ipam_account_pool"
                  from_port   = 1024
                  to_port     = 65535
                },
                {
                  rule_number = 10
                  egress      = true
                  action      = "allow"
                  protocol    = -1
                  cidr_block  = "ipam_account_pool"
                  from_port   = 0
                  to_port     = 0
                }
              ]
            }
          }
          public_subnet_nacl_rules = [
            {
              rule_number = 10
              egress      = false
              action      = "allow"
              protocol    = 6
              cidr_block  = "0.0.0.0/0"
              from_port   = 443
              to_port     = 443
            },
            {
              rule_number = 20
              egress      = false
              action      = "allow"
              protocol    = 6
              cidr_block  = "0.0.0.0/0"
              from_port   = 80
              to_port     = 80
            },
            {
              rule_number = 30
              egress      = false
              action      = "allow"
              protocol    = 6
              cidr_block  = "0.0.0.0/0"
              from_port   = 1024
              to_port     = 65535
            },
            {
              rule_number = 10
              egress      = true
              action      = "allow"
              protocol    = -1
              cidr_block  = "0.0.0.0/0"
              from_port   = 0
              to_port     = 0
            }
          ]
          private_subnet_nacl_rules = [
            {
              rule_number = 10
              egress      = false
              action      = "allow"
              protocol    = 6
              cidr_block  = "0.0.0.0/0"
              from_port   = 1024
              to_port     = 65535
            },
            {
              rule_number = 20
              egress      = false
              action      = "allow"
              protocol    = 6
              cidr_block  = "egress"
              from_port   = 22
              to_port     = 22
            },
            {
              rule_number = 10
              egress      = true
              action      = "allow"
              protocol    = -1
              cidr_block  = "0.0.0.0/0"
              from_port   = 0
              to_port     = 0
            }
          ]
          gw_services = {
            igw_is_enabled       = false
            nat_gw_is_enabled    = false
            nat_gw_type          = "private"
            nat_gw_ha            = false
            vpc_gateway_services = []
            vpc_interface_services = [
              "ec2", "sts"
            ]
            vpc_interface_services_scope = "private"
          }
          tgw_config = {
            route_destinations = ["0.0.0.0/0"]
          }
        }
      }
      transit_gw = {
        tgw_is_enabled = true
        tgw_vpc_attach = ["infra1", "egress"]
        tgw_routes = [
          {
            "destination"    = "0.0.0.0/0"
            "vpc_attachment" = "egress"
          }
        ]
      }
      internet_monitor = {
        is_enabled                    = true
        monitor_vpcs                  = ["egress"]
        traffic_percentage_to_monitor = 50
        max_city_networks_to_monitor  = 100
        availability_threshold        = 96
        performance_threshold         = 96
        status                        = "ACTIVE"
        alarm_config = {
          sns_topics = {
            "egress-alarms" = {}
          }
          sns_subscriptions = [
            {
              topic    = "egress-alarms"
              protocol = "email"
              endpoint = "infra-alerts@example.com"
            }
          ]
          alarms = {
            "egress-availability-score" = {
              description         = "AWS Iternet Monitor Egress availability score less than 96 for 5m."
              comparison          = "LessThanThreshold"
              metric_name         = "AvailabilityScore"
              namespace           = "AWS/InternetMonitor"
              statistic           = "Average"
              period              = 300
              threshold           = 96
              evaluation_periods  = 2
              datapoints_to_alarm = 2
              actions_enabled     = true
              treat_missing_data  = "missing"
              alarm_actions = [
                "egress-alarms"
              ]
            }
            "egress-performance-score" = {
              description         = "AWS Iternet Monitor Egress performance score less than 96 for 5m."
              comparison          = "LessThanThreshold"
              metric_name         = "PerformanceScore"
              namespace           = "AWS/InternetMonitor"
              statistic           = "Average"
              period              = 300
              threshold           = 96
              evaluation_periods  = 2
              datapoints_to_alarm = 2
              actions_enabled     = true
              treat_missing_data  = "missing"
              alarm_actions = [
                "egress-alarms"
              ]
            }
          }
        }
      }
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

module "aws-networking" {
  source                 = "stajkowski/networking/aws"
  version                = "2.1.0"
  project_name           = local.project_name
  environment            = local.environment
  parent_pool_cidr_block = local.parent_pool_cidr_block
  ipam_scope_id          = local.ipam_scope_id
  network_config         = local.network_config[local.environment]
}
```
The following example will create:

1. A parent IPAM pool with CIDR 10.0.0.0/8
2. 2 VPCs, one named "egress" and the other named "infra1" with CIDRs assigned from the parent pool.
3. In the "egress" VPC, 2 public subnets and 2 private with CIDRs assigned from the "egress" VPC pool.
4. In the "infra1" VPC, 2 private subnets with CIDRs assigned from the "infra1" VPC pool.
5. In the "egress" VPC, 1 public route table and 2 private route tables (NAT Gateway HA).
6. In the "infra1" VPC, 1 private route table.
6. NACLs for each public/private subnet and assigned.
7. In the "egress" VPC, an Internet Gateway and 2 NAT Gateways (NAT GW in each public subnet).
8. In the "egress" VPC, a VPCE Gateway is added for "s3" in the public/private route tables.
8. In the "egress" VPC, private link support is added ("ec2 &"sts") to each private subnet since scope is "private".
9. In the "infra1" VPC, private link support is added ("ec2 &"sts") to each private subnet since scope is "private".
10. Two additional private subnets for the "db" group in the "infra1" VPC with NACL rules associated and private route table association.
11. A single Transit Gateway with VPCs "egress" and "infra1" attached.
12. Route destination "0.0.0.0/0" is added to the private route tables in "infra1" VPC.
13. Route destination "infra1" (auto substituted for infra 1 CIDR) is added to public/private route tables in "egress" VPC.
14. A default security group that can be used per VPC that allows parent IPAM pool CIDR of "10.0.0.0/8"
15. Internet Monitor enabled and monitoring egress VPC.
16. SNS Topic for Internet Monitor Alerts and 1 subscription with email as the protocol.
17. 2 CloudWatch alarms for Availability and Performances score utilizing the SNS topic for alerts.

*NOTE*: Size of each VPC CIDR and subnet mask can be controlled through the configuration "vpc_cidr_subnet_mask" and "subnet_mask"

## Requirements

| Name      | Version   |
|-----------|-----------|
| Terraform | >= 1.0.0  |
| aws       | ~> 5.0.0 |

## Providers

| Name      | Version   |
|-----------|-----------|
| aws       | ~> 5.0.0 |

## Resources

| Name                                                        | Type     |
|-------------------------------------------------------------|----------|
| aws_ec2_transit_gateway.transit_gateway                     | resource |
| aws_ec2_transit_gateway_vpc_attachment.transit_gateway      | resource |
| aws_eip.nat_eip                                             | resource |
| aws_internet_gateway.igw                                    | resource |
| aws_nat_gateway.nat_gw                                      | resource |
| aws_network_acl.private_subnet_nacl                         | resource |
| aws_network_acl.public_subnet_nacl                          | resource |
| aws_network_acl_association.private_subnet_nacl_association | resource |
| aws_network_acl_association.public_subnet_nacl_association  | resource |
| aws_network_acl_rule.private_subnet_nacl_rules              | resource |
| aws_network_acl_rule.public_subnet_nacl_rules               | resource |
| aws_route.igw_default_route                                 | resource |
| aws_route.nat_gw_default_route                              | resource |
| aws_route.tgw_route                                         | resource |
| aws_route_table.private_route_table                         | resource |
| aws_route_table.public_route_table                          | resource |
| aws_route_table_association.private_subnet_association      | resource |
| aws_route_table_association.public_subnet_association       | resource |
| aws_security_group.vpc_default_sg                           | resource |
| aws_subnet.private_subnet                                   | resource |
| aws_subnet.public_subnet                                    | resource |
| aws_vpc.vpc_network                                         | resource |
| aws_vpc_endpoint.vpc_gateway_endpoint                       | resource |
| aws_vpc_endpoint.vpc_interface_endpoint                     | resource |
| aws_vpc_ipam.account_ipam                                   | resource |
| aws_vpc_ipam_pool.acct_ipam_pool                            | resource |
| aws_vpc_ipam_pool.vpc_subnet_ipam_pool                      | resource |
| aws_vpc_ipam_pool_cidr.acct_ipam_pool_cidr                  | resource |
| aws_vpc_ipam_pool_cidr.vpc_subnet_ipam_pool_cidr            | resource |
| aws_vpc_ipam_pool_cidr_allocation.vpc_ipam_pool_private     | resource |
| aws_vpc_ipam_pool_cidr_allocation.vpc_ipam_pool_public      | resource |

## Inputs
| Name      | Description   | Type    |
|-----------|-----------|-----------|
| project_name | Generally referred to as the namespace. This can be any value used to identify the parent set of objects created in the environment. | `string`
| environment | Current environment stage to configure.  This value is only utilized in naming resources and applying tags. | `string`
| parent_pool_cidr_block | CIDR block for Environment Parent VPC Pools, i.e. 10.0.0.0/8. | `string`
| ipam_scope_id | Existing IPAM scope ID for Environment VPC Parent Pool Creation.  Use standard ARN format for Scope ID. i.e. `ipam-scope-04dd36eca6021f93e`.  | `string`
| network_config | Network configuration values utilized to standup VPC resources. `object({vpcs={},transit_gw={},internet_monitor={}})` | `object()`

#### Network Configuration Inputs (VPC)
| Name      | Description   | Type    |
|-----------|-----------|-----------|
| vpcs.public_subnets | Number of public subnets to create in the VPC.  This is required to be > 0 if an Internet Gateway is configured for the VPC. | `number`
| vpcs.private_subnets | Number of private subnets to create in the VPC.  This is required to be > 0 if a priate NAT Gateway is configured for the VPC. | `number`
| vpcs.vpc_cidr_subnet_mask | Length of mask for auto assignment of the VPC CIDR. | `number`
| vpcs.subnet_mask | Length of mask for auto assignment of VPC Subnets. | `number`
| vpcs.additional_private_subnets | Map of additional private subnets to create and associate with private route table with NACL rules. | `map(object{})`
| vpcs.additional_private_subnets.`id`.subnet_count | The number of subnets to create for this additional private subnet group. | `number`
| vpcs.additional_private_subnets.`id`.nacl_rules | This will iterate over the configured NACL rules and assign them to the private subnet group subnet ids. This is direct configuration of NACL Rules in AWS with support for dynamic names of VPCs in the cidr_block within aws-networking module.  It is possible to supply a standard CIDR  for `cidr_block` such as "10.0.0.0/8" or "0.0.0.0/0", but alternatively you can pass the key value under "vpcs", which is the name of your VPC.  aws-networking module will then replace the VPC name with the assigned CIDR. Additionally, `ipam_account_pool` can be set for the `cidr_block` to replace this value with the configured account level pool or parent pool. | `list(object())`
| vpcs.gw_services.igw_is_enabled | Boolean value to indicate if an Internet Gateway is to be configured for the VPC. | `bool`
| vpcs.gw_services.nat_gw_is_enabled | Boolean value to indicate if a NAT Gateway is to be configured for the VPC. | `bool`
| vpcs.gw_services.nat_gw_type | (`public`, `private`) NAT Gateway type is direct confgiuration of the aws module and can be public or private.  Public NAT Gateway requires creation of an Internet Gateway to allow traffic to exit to the Internet. Private NAT Gateways: https://docs.aws.amazon.com/whitepapers/latest/building-scalable-secure-multi-vpc-network-infrastructure/private-nat-gateway.html. Public NAT Gateway Architecture: https://docs.aws.amazon.com/network-firewall/latest/developerguide/arch-igw-ngw.html | `string`
| vpcs.gw_services.nat_gw_ha | Boolean to configure NAT Gateway in High Availability.  Essentially this creates a route table per private subnet and associates an EIP and NAT Gateway per route table.  This is the recommended configuration for High Availability. | `bool`
| vpcs.gw_services.vpc_gateway_services | This is a list of VPCE Gateway services to create and associate with public/private subnets.  Please refer to AWS Documentation on which services support VPCE Gateway but as of this release, only "s3" and "dynamodb" are supported. | `list(string)`
| vpcs.gw_services.vpc_interface_services | This is a list of services to create Interface Endpoints (PrivateLink).  The difference between VPCE Gateway and Interface Endpoint (PrivateLink), is that Interface Endpoint allows access to AWS services through an IP Address assigned from within your subnets, whereas, VPCE Gateway endpoints inject routes into your associated routing tables. Please refer to AWS documentation for supported services (https://docs.aws.amazon.com/vpc/latest/privatelink/aws-services-privatelink-support.html) and please use the service name in the endpoint, i.e. for "com.amazonaws.us-east-1.s3" you would set this configuration to ["s3"] | `list(string)`
| vpcs.gw_services.vpc_interface_services_scope | (`private`, `both`) This will control in aws-networking module which subnets to attach to the Interface Endpoint.  `private` will attach only private subnets, whereas `both` will assign both public and private subnets to the Interface Endpoint.
| vpcs.public_subnet_nacl_rules | This will iterate over the configured NACL rules and assign them to the public subnet ids. This is direct configuration of NACL Rules in AWS with support for dynamic names of VPCs in the cidr_block within aws-networking module.  It is possible to supply a standard CIDR for `cidr_block` such as "10.0.0.0/8" or "0.0.0.0/0", but alternatively you can pass the key value under "vpcs", which is the name of your VPC.  aws-networking module will then replace the VPC name with the assigned CIDR.  Additionally, `ipam_account_pool` can be set for the `cidr_block` to replace this value with the configured account level pool or parent pool. | `list(object())`
| vpcs.private_subnet_nacl_rules | This will iterate over the configured NACL rules and assign them to the private subnet ids. This is direct configuration of NACL Rules in AWS with support for dynamic names of VPCs in the cidr_block within aws-networking module.  It is possible to supply a standard CIDR  for `cidr_block` such as "10.0.0.0/8" or "0.0.0.0/0", but alternatively you can pass the key value under "vpcs", which is the name of your VPC.  aws-networking module will then replace the VPC name with the assigned CIDR. Additionally, `ipam_account_pool` can be set for the `cidr_block` to replace this value with the configured account level pool or parent pool. | `list(object())`
| vpcs.tgw_config.route_destinations | This will configure routes within the VPC Route Tables to the Transit Gateway. The configured value can be static, such as "0.0.0.0/0", or dynamic, similar to the NACL rules.  When using dynamic, utilize the VPC name you assigned to the VPC under "vpcs".  aws-networking module will replace the VPC name with the assigned CIDR. | `list(string)`

#### Network Configuration Inputs (Transit Gateway)
| Name      | Description   | Type    |
|-----------|-----------|-----------|
| transit_gw.tgw_is_enabled | Boolean value to indicate that aws-networking should create a Transit Gateway. | `bool`
| transit_gw.tgw_vpc_attach | List of named VPCs to attach to the Transit Gateway. | `list(string)`
| transit_gw.tgw_routes | List of routes to add into the Transit Gateway. | `list(object())`
| transit_gw.tgw_routes.*.destination | Destination route, such as `0.0.0.0/0` or a VPC name like `egress`. | `string`
| transit_gw.tgw_routes.*.vpc_attachment | Name of the VPC that is attached to Transit Gateway in `transit_gw.tgw_vpc_attach`. This will point the destination toward the VPC named in this parameter. | `string`

#### Network Configuration Inputs (Iternet Monitor)
| Name      | Description   | Type    |
|-----------|-----------|-----------|
| internet_monitor.is_enabled | Boolean value to indicate that aws-networking should enable Internet Monitor. | `bool`
| internet_monitor.monitor_vpcs | List of named VPCs to enable Internet Monitor. | `list(string)`
| internet_monitor.traffic_percentage_to_monitor | https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/IMTrafficPercentage.html | `number`
| internet_monitor.max_city_networks_to_monitor | https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/IMCityNetworksMaximum.html | `number`
| internet_monitor.availability_threshold | https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-IM-overview.html#IMUpdateThresholdFromOverview | `number`
| internet_monitor.performance_threshold | https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-IM-overview.html#IMUpdateThresholdFromOverview | `number`
| internet_monitor.status | (`ACTIVE`,`INACTIVE`) Set Internet Monitor status. | `number`
| internet_monitor.alarm_config | Iternet Monitor alarm configuration for SNS Topics, Subscriptions, and CloudWatch Alarms. | `object()`
| internet_monitor.alarm_config.sns_topics | Named SNS Topics created based on key value.  Object value not used and reserved for future use. | `map()`
| internet_monitor.alarm_config.sns_subscriptions | List of objects containing the SNS subscriptions: topic, protocol, and endpoint. https://docs.aws.amazon.com/sns/latest/api/API_Subscribe.html | `object()`
| internet_monitor.alarm_config.alarms | Map of alarms to create, please refer to CloudWatch documentation on exact settings to support your use case: https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_PutMetricAlarm.html | `map(object())`

## Revision Updates

#### Version 1.0.0 (Initial Release)

1. Support for any number of VPCs.
2. Creation of a dynamic set of public and private subnets.
3. Auto VPC and Subnet CIDR assignments from parent IPAM pool.
4. Route table configuration for HA NAT Gateway (1 Route Table / Subnet).
5. Subnet NACL support with auto shorthand replacement of VPC names to VPC CIDR.
6. A default Security Group that can be used or referenced with parent pool CIDR.
7. Internet Gateway confgiuration.
8. NAT Gateway configuration for public/private and HA support.
9. VPCE Gateway service support for AWS services such as "S3" and "Dyanmodb".
10. Interface Gateway (PrivateLink) support in 2 config modes (public/private).
11. Public Interface Gateway will associate interface gateway with both public and private subnets.
12. Private Interface Gateway will associate interface gateway with private subnets only.
13. Transit Gateway with VPC assignment.
14. Transit Gateway route updates for every route table in the assigned VPC.

#### Version 2.0.0

1. Support for additional named private subnets.

#### Version 2.2.0

1. [2.1.0] Add support to configure existing IPAM scope ID.
2. Add observability with configuration of Internet Monitor for selected VPCs.
3. Add support to configure SNS topics, subscriptions and alarms for Iternet Monitor.

## Required Permissions
```
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "IPAMActions",
			"Effect": "Allow",
			"Action": [
				"ec2:ModifyIpam",
				"ec2:GetIpamResourceCidrs",
				"ec2:GetIpamPoolCidrs",
				"ec2:DescribeIpamScopes",
				"ec2:CreateTags",
				"ec2:CreateIpamPool",
				"ec2:ModifyIpamScope",
				"ec2:DescribeIpamPools",
				"ec2:DeleteIpam",
				"ec2:CreateIpam",
				"ec2:ModifyIpamPool",
				"ec2:DeleteIpamScope",
				"ec2:DeprovisionIpamPoolCidr",
				"ec2:CreateIpamScope",
				"ec2:AllocateIpamPoolCidr",
				"ec2:ReleaseIpamPoolAllocation",
				"ec2:DescribeIpams",
				"ec2:ProvisionIpamPoolCidr",
				"ec2:DeleteIpamPool",
				"ec2:GetIpamPoolAllocations",
				"iam:CreateServiceLinkedRole"
			],
			"Resource": "*"
		},
		{
			"Sid": "InternetMonitor",
			"Effect": "Allow",
			"Action": [
				"internetmonitor:*",
				"sns:CreateTopic",
				"sns:DeleteTopic",
				"sns:GetTopicAttributes",
				"sns:ListSubscriptionsByTopic",
				"sns:ListTagsForResource",
				"sns:SetTopicAttributes",
				"sns:Subscribe",
				"sns:Unsubscribe",
				"cloudwatch:DeleteAlarms",
				"cloudwatch:DescribeAlarms",
				"cloudwatch:DisableAlarmActions",
				"cloudwatch:EnableAlarmActions",
				"cloudwatch:PutMetricAlarm",
				"cloudwatch:TagResource",
				"cloudwatch:UntagResource"
			],
			"Resource": "*"
		},
		{
			"Sid": "VPCActions",
			"Effect": "Allow",
			"Action": [
				"ec2:AllocateAddress",
				"ec2:AssignIpv6Addresses",
				"ec2:AssignPrivateIpAddresses",
				"ec2:AssociateAddress",
				"ec2:AssociateRouteTable",
				"ec2:AssociateSubnetCidrBlock",
				"ec2:AssociateVpcCidrBlock",
				"ec2:AttachInternetGateway",
				"ec2:AttachNetworkInterface",
				"ec2:AuthorizeSecurityGroupIngress",
				"ec2:AuthorizeSecurityGroupEgress",
				"ec2:CreateDefaultSubnet",
				"ec2:CreateDefaultVpc",
				"ec2:CreateInternetGateway",
				"ec2:CreateNatGateway",
				"ec2:CreateTransitGateway",
				"ec2:CreateTransitGatewayRoute",
				"ec2:CreateTransitGatewayRouteTable",
				"ec2:CreateTransitGatewayVpcAttachment",
				"ec2:DeleteTransitGateway",
				"ec2:DeleteTransitGatewayRoute",
				"ec2:DeleteTransitGatewayRouteTable",
				"ec2:DeleteTransitGatewayVpcAttachment",
				"ec2:DescribeTransitGatewayAttachments",
				"ec2:DescribeTransitGatewayRouteTables",
				"ec2:DescribeTransitGatewayVpcAttachments",
				"ec2:DescribeTransitGateways",
				"ec2:DescribePrefixLists",
				"ec2:ModifyTransitGateway",
				"ec2:ModifyTransitGatewayVpcAttachment",
				"ec2:CreateNetworkAcl",
				"ec2:CreateNetworkAclEntry",
				"ec2:CreateNetworkInterface",
				"ec2:CreateNetworkInterfacePermission",
				"ec2:CreateRoute",
				"ec2:CreateRouteTable",
				"ec2:CreateSecurityGroup",
				"ec2:CreateSubnet",
				"ec2:CreateTags",
				"ec2:CreateVpc",
				"ec2:CreateVpcEndpoint",
				"ec2:CreateVpcEndpointServiceConfiguration",
				"ec2:DeleteInternetGateway",
				"ec2:DeleteNatGateway",
				"ec2:DeleteNetworkAcl",
				"ec2:DeleteNetworkAclEntry",
				"ec2:DeleteNetworkInterface",
				"ec2:DeleteNetworkInterfacePermission",
				"ec2:DeleteRoute",
				"ec2:DeleteRouteTable",
				"ec2:DeleteSecurityGroup",
				"ec2:DeleteSubnet",
				"ec2:DeleteTags",
				"ec2:DeleteVpc",
				"ec2:DeleteVpcEndpoints",
				"ec2:DeleteVpcEndpointServiceConfigurations",
				"ec2:DescribeAccountAttributes",
				"ec2:DescribeAddresses",
				"ec2:DescribeAvailabilityZones",
				"ec2:DescribeInternetGateways",
				"ec2:DescribeIpv6Pools",
				"ec2:DescribeNatGateways",
				"ec2:DescribeNetworkAcls",
				"ec2:DescribeNetworkInterfaceAttribute",
				"ec2:DescribeNetworkInterfacePermissions",
				"ec2:DescribeNetworkInterfaces",
				"ec2:DescribeRouteTables",
				"ec2:DescribeSecurityGroupReferences",
				"ec2:DescribeSecurityGroupRules",
				"ec2:DescribeSecurityGroups",
				"ec2:DescribeStaleSecurityGroups",
				"ec2:DescribeSubnets",
				"ec2:DescribeTags",
				"ec2:DescribeVpcAttribute",
				"ec2:DescribeVpcEndpointConnections",
				"ec2:DescribeVpcEndpoints",
				"ec2:DescribeVpcEndpointServiceConfigurations",
				"ec2:DescribeVpcEndpointServicePermissions",
				"ec2:DescribeVpcEndpointServices",
				"ec2:DescribeVpcs",
				"ec2:DetachInternetGateway",
				"ec2:DetachNetworkInterface",
				"ec2:DisassociateAddress",
				"ec2:DisassociateRouteTable",
				"ec2:DisassociateSubnetCidrBlock",
				"ec2:DisassociateVpcCidrBlock",
				"ec2:GetSecurityGroupsForVpc",
				"ec2:GetTransitGatewayRouteTableAssociations",
				"ec2:GetTransitGatewayRouteTablePropagations",
				"ec2:ModifyNetworkInterfaceAttribute",
				"ec2:ModifySecurityGroupRules",
				"ec2:ModifySubnetAttribute",
				"ec2:ModifyVpcAttribute",
				"ec2:ModifyVpcEndpoint",
				"ec2:ModifyVpcEndpointServiceConfiguration",
				"ec2:ModifyVpcEndpointServicePermissions",
				"ec2:RejectVpcEndpointConnections",
				"ec2:ReleaseAddress",
				"ec2:ReplaceNetworkAclAssociation",
				"ec2:ReplaceNetworkAclEntry",
				"ec2:ReplaceRoute",
				"ec2:ReplaceRouteTableAssociation",
				"ec2:ResetNetworkInterfaceAttribute",
				"ec2:RevokeSecurityGroupEgress",
				"ec2:RevokeSecurityGroupEgress",
				"ec2:SearchTransitGatewayRoutes",
				"ec2:UnassignIpv6Addresses",
				"ec2:UnassignPrivateIpAddresses",
				"ec2:DeleteDhcpOptions"
			],
			"Resource": "*"
		}
	]
}
```

## License

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## About
[![text](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/brian-stajkowski-a99b9b5/)

### Brian Stajkowski
With over 20 years of experience in the IT industry from networking to building cloud services at massive scale, DevOps has been a continued interest.  Feel free to use any or all of the modules contained in this respository, and submit any use cases that further expand this abstraction in bulding complex virtual networks in AWS.  Connect with me on LiknkedIn!

https://www.linkedin.com/in/brian-stajkowski-a99b9b5/

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)