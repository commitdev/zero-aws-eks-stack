# Overview
[![Validation Status](https://github.com/commitdev/zero-aws-eks-stack/workflows/Validate%20Terraform/badge.svg)](https://github.com/commitdev/zero-aws-eks-stack/actions)

A set of templates meant to work with [Zero], the templated result is a ready to scale infrastructure boilerplate built on top of AWS EKS baked with all best practices we have accumulated.

## Repository structure
The root folder is used for declaring parameters required by the templates, and [Zero][zero] will gather the required parameters and parse the templates as individual repositories for user to maintain.
```sh
/   # file in the root directory is for initializing the user's repo and declaring metadata
|-- Makefile                        #make command triggers the initialization of repository
|-- zero-module.yml                 #module declares required parameters and credentials
|
|   # files in templates become the repo for users
|   templates/
|   |   # this makefile is used both during init and
|   |   # on-going needs/utilities for user to maintain their infrastructure
|   |-- Makefile
|   |-- terraform/
|   |   |-- bootstrap/              #initial setup
|   |   |-- environments/           #infrastructure setup
|   |   |   |-- prod/
|   |   |   |-- stage/
|   |-- kubernetes
|   |   |-- terraform
|   |   |   |-- environments        #k8s-ultities
|   |   |   |   |-- prod/
|   |   |   |   |-- stage/
```

## AWS EKS Stack
The Zero-aws-eks stack is designed with scalability and maintainability in mind, this repo is a series of templates indented to be filled in with modules parameters, and executed by zero
This is a [Zero][zero] module which sets up a
hosting environment on AWS running Kubernetes. It will generate terraform output
which describes the environment mapped in this [architecture diagram][arch-diagram].

**Resource List**: [Link][resource-list]

**Prerequisites**
 - Terraform installed
 - Kubectl installed
 - Wget installed
 - A valid AWS account
 - [Set up the AWS CLI][aws-cli]
 - [A domain registered with Route53][aws-route53]
   - Note: if you want to use different domain per environment (staging/production), you need to have multiple hosted zones. The available zones in Route53 can be found by running this command. `aws route53 list-hosted-zones`

_Optional Prerequisites_
- [Sendgrid account][sendgrid] with developer [API key][sendgrid-apikey]: this will enable transactional email sending with simple API calls.

## Getting Started

This is meant to be used with the `zero` tool and not directly. See
the [Zero][zero] repository for more
information. The tool will parse through configuration and fill in any
template variables which need to be encoded into the terraform configuration.

### Testing and linting
The codebase uses terraform validate as a basic sanity check, it uses
[an example zero-project.yml fixture][ci-fixture] to fill-in the templates, then runs
`terraform init` and `terraform validate` against the templated out environment and modules.

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

EC2 instance sizing can be configured in [templates/terraform/environments/stage/main.tf](templates/terraform/environments/stage/main.tf)

## Other links
Project board: [zenhub][zenhub-board]

<!-- Links -->
[zero]: https://github.com/commitdev/zero
[arch-diagram]: ./docs/architecture-overview.svg
[resource-list]: ./docs/resources.md
[ci-fixture]: tests/fixtures/test-project/zero-project.yml
<!-- External Links -->
[aws-cli]: https://docs.aws.amazon.com/polly/latest/dg/setup-aws-cli.html
[aws-route53]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-register.html
[zenhub-board]: https://app.zenhub.com/workspaces/commit-zero-5da8decc7046a60001c6db44/board?filterLogic=any&repos=203630543,247773730,257676371,258369081
[sendgrid]: https://signup.sendgrid.com
[sendgrid-apikey]: https://app.sendgrid.com/settings/api_keys
