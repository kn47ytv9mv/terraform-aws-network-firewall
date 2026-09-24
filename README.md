# terraform-aws-network-firewall

Terraform module for an AWS Network Firewall — stateful traffic
inspection deployed into a VPC, enforcing a
[`terraform-aws-network-firewall-policy`](https://github.com/kn47ytv9mv/terraform-aws-network-firewall-policy).

## Cost

Network Firewall bills per-hour per availability zone the firewall has
an endpoint in (one `subnet_mapping` entry each), plus a per-GB charge
for traffic it processes. Both apply regardless of how much traffic
actually crosses the firewall. See AWS's
[Network Firewall pricing](https://aws.amazon.com/network-firewall/pricing/)
page for current rates.

## Design

This module creates only the firewall itself, in the classic VPC
deployment model — one endpoint per `subnet_mapping` entry, each
getting its own ENI. It does not create the dedicated inspection
subnets that model typically calls for (pair with
[`terraform-aws-vpc`](https://github.com/kn47ytv9mv/terraform-aws-vpc)),
and does not support AWS's newer Transit-Gateway-native attachment
mode, where the firewall attaches directly to a
[`terraform-aws-transit-gateway`](https://github.com/kn47ytv9mv/terraform-aws-transit-gateway)
instead of a VPC — a deliberately narrower scope than "every Network
Firewall deployment model."

Creating the firewall does not by itself route any traffic through
it — each subnet meant to be inspected needs its own route table entry
pointing at the matching availability zone's endpoint, found in the
`firewall_status` output. Traffic that never gets routed to a firewall
endpoint is never inspected, silently.

## Usage

```hcl
module "firewall" {
  source = "kn47ytv9mv/network-firewall/aws"

  firewall_policy_arn = module.policy.arn
  vpc_id               = module.vpc.id

  subnet_mapping = [
    { subnet_id = module.firewall_subnet_a.id },
    { subnet_id = module.firewall_subnet_b.id },
  ]
}
```

Or directly from this repository, with delete protection for a
production deployment:

```hcl
module "firewall" {
  source = "github.com/kn47ytv9mv/terraform-aws-network-firewall"

  firewall_policy_arn = module.policy.arn
  vpc_id               = module.vpc.id

  subnet_mapping = [
    { subnet_id = module.firewall_subnet_a.id },
    { subnet_id = module.firewall_subnet_b.id },
  ]

  delete_protection                 = true
  firewall_policy_change_protection = true
}
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.3 |
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Providers

| Name | Version |
|---|---|
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| name | Name of the firewall. If null, a unique name is generated. | `null` | no |
| description | A description of the firewall. | `null` | no |
| firewall_policy_arn | The ARN of the firewall policy this firewall enforces, from terraform-aws-network-firewall-policy's arn output. | `null` | no |
| vpc_id | The ID of the VPC to deploy the firewall's endpoints into. | `null` | no |
| subnet_mapping | Subnets to deploy a firewall endpoint into, one per availability zone — AWS creates one ENI per entry, and every subnet routing through this firewall needs an entry for its own AZ. | `[]` | no |
| delete_protection | Whether to prevent the firewall from being deleted while this is true. If null, AWS's own default (false) applies. | `null` | no |
| firewall_policy_change_protection | Whether to prevent firewall_policy_arn from being changed while this is true. If null, AWS's own default (false) applies. | `null` | no |
| subnet_change_protection | Whether to prevent subnet_mapping from being changed while this is true. If null, AWS's own default (false) applies. | `null` | no |
| tags | A map of tags to assign to the firewall. | `null` | no |
| logging_destinations | Logs streamed off the firewall. `log_type` is `'FLOW'`, `'ALERT'`, or `'TLS'`; `log_destination_type` is `'S3'`, `'CloudWatchLogs'`, or `'KinesisDataFirehose'`; `log_destination` keys depend on the type. Supplying a destination enables logging. | `[]` | no |

## Outputs

| Name | Description |
|---|---|
| id | The ID of the firewall. |
| arn | The ARN of the firewall. |
| firewall_status | Sync status of the firewall's endpoints per availability zone, including each endpoint's ID — needed to add a route through the firewall in each subnet's route table. |
| name | The name of the firewall. |

## License

MIT — see [LICENSE.md](LICENSE.md).
