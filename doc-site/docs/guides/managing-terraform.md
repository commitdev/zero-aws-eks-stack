---
title: Managing your Terraform Infrastructure as Code
sidebar_label: Managing Terraform
sidebar_position: 1
---

## Managing your Terraform
#### Why terraform
The repository follows infrastructure as code as a core principle, it allows repeatable and reproducible infrastructures and makes DevOps much more manageable; to learn more about it we suggest reading the [Terraform's workflow guide][tf-workflow].

#### Intended workflows
To make changes to the infrastructure you would modify the terraform code changing the components you wish to modify, then plan the changes with `terraform plan` to make sure you are making the desired changes; then apply the changes with `terraform apply` on your staging environment. Once you reach the satisfactory state, you should do the same on production environment and check-in the changes of your infrastructure code, as this repo should be the source of truth of your deployed infrastructure.
Our infrastructure is divided into a few areas.
1. Initial setup
  - [remote state][tf-remote-state]
  - [secrets][tf-secrets]
2. Infrastructure
  - [production][tf-production-env]
  - [staging][tf-staging-env]
3. Kubernetes utilities
  - [production][tf-production-utilities]
  - [staging][tf-staging-utilities]

#### Style guide, resources, and Configuring your infrastructure as code
For more information about the terraform in this repo, please see [Link][zero-tf-guide]


## Guidelines & Style Convention Summary

- All Terraform configuration should be formatted with `terraform fmt` before being accepted into this repository.
- This repository is Terraform version >= 0.13, as such, leverage features from this release whenever possible.
    See https://www.terraform.io/upgrade-guides/0-13.html for more information.
- Leverage community-maintained Terraform modules whenever possible.
- Attempt to minimize duplication whenever possible, but only within reason -- sometimes duplication is an acceptable solution.
- Whenever possible, define the types of variables.


### Environment Conventions

- `terraform/environments/` contains the configuration for specific environments (staging, production, etc.)
- All environments should contain the following:

    `main.tf`: Top level terraform configuration file that instantiates the `environment` module and provides configuration values.

- Configuration should be pushed "top->down" from the `environment` module to it's submodules.
- If there is some feature that is specific to a single environment it could be put into another `.tf` file in the `environments/<env>` directory, but as much as possible, try to work with reusable modules instead.
- Many modules are provided from the Zero terraform registry. These specify a version number. To take advantage of a new fix or feature in one of these modules, just change the version number and run `terraform init` to pull in the new code.


### The Environment Module

- The `environment` module can be considered the top-level module, all other modules are imported from this module.
- Environment-specific variables should be exposed via the `variables.tf` file in this module, where they will be set from within the appropriate environment in the `environments/` directory.
- The `environment` module contains the following:

    `main.tf`: Module entrypoint where instantiation of resources happens.
    `provider.tf`: Provider configuration.
    `variables.tf`: Environment-specific variables are declared here.
    `versions.tf`: Terraform version information.


### Module Conventions

- Modules should be used to provide functionality that will be used in multiple environments. The `environment` module is the place where all shared modules are used.
- All modules should contain the following:

    `README.md`: A description of the module.
    `main.tf`: Module entrypoint where instantiation of resources happens.
    `variables.tf`: Module variables.
    `outputs.tf`: Output values.
    `files/`: Any non-Terraform files required by the module.

- All module variables must have a description.
- Again, leverage community-maintained Terraform modules whenever possible.
- Avoid writing a module that is simply a wrapper of a Terraform resource unless absolutely necessary.

## Directory Structure

```
    README.md
    environments/
        prod/
            main.tf
        stage/
            main.tf
    modules/
        environment/
            ...
        <module-a>/
            files/
            scripts/
            main.tf
            outputs.tf
            variables.tf
        <module-n>/
        ...
```

[tf-workflow]: https://www.terraform.io/guides/core-workflow.html

[zero-tf-guide]: https://github.com/commitdev/zero-aws-eks-stack/tree/main/templates/terraform/README.md
<!-- code -->
[tf-remote-state]: https://github.com/commitdev/zero-aws-eks-stack/tree/main/templates/terraform/bootstrap/remote-state
[tf-secrets]: https://github.com/commitdev/zero-aws-eks-stack/tree/main/templates/terraform/bootstrap/secrets
[tf-production-env]: https://github.com/commitdev/zero-aws-eks-stack/tree/main/templates/terraform/environments/prod
[tf-staging-env]: https://github.com/commitdev/zero-aws-eks-stack/tree/main/templates/terraform/environments/stage
[tf-production-utilities]: https://github.com/commitdev/zero-aws-eks-stack/tree/main/templates/kubernetes/terraform/environments/prod
[tf-staging-utilities]: https://github.com/commitdev/zero-aws-eks-stack/tree/main/templates/kubernetes/terraform/environments/stage