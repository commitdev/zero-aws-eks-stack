# AWS EKS Stack

This is a [zero](https://github.com/commitdev/zero) module which sets up a
hosting environment on AWS running Kubernetes. It will generate terraform output
which describes the environment mapped in this [architecture
diagram](./templates/docs/architecture-overview.svg).

**Prerequisites**
 - Terraform installed
 - Kubectl installed
 - Wget installed
 - A valid AWS account
 - [Set up the AWS CLI](https://docs.aws.amazon.com/polly/latest/dg/setup-aws-cli.html)
 - [A domain registered with Route53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-register.html)
   - Note: if you want to use different domain per environment (staging/poduction), you need to have multiple hosted zones. The available zones in Route53 can be found by running this command. `aws route53 list-hosted-zones`

## Getting Started

This is meant to be used with the `zero` tool and not directly. See
the [zero](https://github.com/commitdev/zero) repository for more
information. The tool will parse through configuration and fill in any
template variables which need to be encoded into the terraform configuration.

### How much does this stack cost?
The expected total monthly cost: $ 0.202 USD / hr or ~$150USD / month. The most
expensive component will be the EKS cluster as well as the instances that it
spins up. Costs will vary depending on the region selected but based on
`us-west-2` the following items will contribute to the most of the cost of the
infrastructure:
 - EKS Cluster: $0.1 USD / hr
 - NAT Gateway: $0.045 USD / hr
 - RDS (db.t3.small): $0.034 USD / hr
 - EC2 (t2.small): $0.023 USD / hr

EC2 instance sizing can be configured in [terraform/environments/staging/main.tf](terraform/environments/staging/main.tf)
