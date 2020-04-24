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
   - Note: if you want to use different domain per environment (staging/poduction), you need to have multiple hosted zones. The available zones in Route53 can be found by running this command. `aws route53 list-hosted-zones`

## Getting Started

This is meant to be used with the commit0 `stack` tool and not directly. See
the [stack](https://github.com/commitdev/stack) repository for more
information. The tool will parse through configuration and fill in any
template variables which need to be encoded into the terraform configuration.
Once that is done you'll have a directory containing the contents of this
repository minus the `.git` directory.

To generate the templates you will need to provide some values to fill in.

First get the AMI for your region:
```shell
$ REGION=us-east-1
$ aws ssm get-parameters \
  --names /aws/service/eks/optimized-ami/1.15/amazon-linux-2/recommended/image_id \
  --region $REGION \
  --query "Parameters[0].Value"
```

Then get the aws account id:
```shell
aws sts get-caller-identity --query "Account"
```

Then create a `config.yml` file and fill in the appropriate values:

```yaml
name: my-project

params:
  region: us-east-1
  accountId: <from above>
  kubeWorkerAMI: ami-<from above>
  productionHost: domain.com
  stagingHost: domain-staging.com
```

And run `stack`:
```shell
$ stack -config config.yml commit0-aws-eks-stack/ my-project-infrastructure/
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
$ aws eks update-kubeconfig --name <cluster-name> --region us-east-1
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
