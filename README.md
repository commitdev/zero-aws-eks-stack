# AWS EKS Stack

This is a [Commit0](https://github.com/commitdev/commit0) module which sets up a
hosting environment on AWS running Kubernetes. It will generate terraform output
which describes the environment mapped in this [architecture
diagram](./docs/architecture-overview.svg).

**Prerequisites**
 - Terraform installed
 - Kubectl installed
 - A valid AWS account
 - [Set up the AWS CLI](https://docs.aws.amazon.com/polly/latest/dg/setup-aws-cli.html)
 - [A domain registered with Route53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-register.html)

## Getting Started

This is meant to be used with commit0 and not directly. See
the [commit0](https://github.com/commitdev/commit0) repository for more
information. The commit0 tool will parse through configuration and fill in any
template variables which need to be encoded into the terraform configuration.
Once that is done you'll have a directory containing the contents of this
repository minus the `.git` directory.

### ⚠️ Edits Required

This repository requires post-template configuration edits to the AMI depending
on the region you chose. To find the appropriate AMI for your region you can use
the following snippet:

```shell
$ REGION=us-east-2
$ aws ssm get-parameters \
  --names /aws/service/eks/optimized-ami/1.15/amazon-linux-2/recommended/image_id \
  --region $REGION \
  --query "Parameters[0].Value" | cat
```

### Apply Configuration
To init and apply the terraform configs, simply run the `make` and specify the
environment. The default environment is `staging`
```shell
$ make ENV=<environment>
```

### Set up an application
Configure your k8s context

```shell
$ aws eks update-kubeconfig --name <cluster-name> --region us-west-2
```

Then talk to Bill.

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
